require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR >= 3
  require 'active_support/core_ext'
end
require 'to_regexp'

# See the README for more information.
class FuzzyMatch
  autoload :Tightener, 'fuzzy_match/tightener'
  autoload :StopWord, 'fuzzy_match/stop_word'
  autoload :Blocking, 'fuzzy_match/blocking'
  autoload :Identity, 'fuzzy_match/identity'
  autoload :Result, 'fuzzy_match/result'
  autoload :Wrapper, 'fuzzy_match/wrapper'
  autoload :Similarity, 'fuzzy_match/similarity'
  autoload :Score, 'fuzzy_match/score'
  autoload :CachedResult, 'fuzzy_match/cached_result'
  
  attr_reader :haystack
  attr_reader :blockings
  attr_reader :identities
  attr_reader :tighteners
  attr_reader :stop_words
  attr_reader :default_first_blocking_decides
  attr_reader :default_must_match_blocking
  attr_reader :default_must_match_at_least_one_word

  # haystack - a bunch of records
  # options
  # * tighteners: regexps (see readme)
  # * identities: regexps
  # * blockings: regexps
  # * stop_words: regexps
  # * read: how to interpret each entry in the 'haystack', either a Proc or a symbol
  def initialize(records, options = {})
    options = options.symbolize_keys
    @default_first_blocking_decides = options[:first_blocking_decides]
    @default_must_match_blocking = options[:must_match_blocking]
    @default_must_match_at_least_one_word = options[:must_match_at_least_one_word]
    @blockings = options.fetch(:blockings, []).map { |regexp_or_str| Blocking.new regexp_or_str }
    @identities = options.fetch(:identities, []).map { |regexp_or_str| Identity.new regexp_or_str }
    @tighteners = options.fetch(:tighteners, []).map { |regexp_or_str| Tightener.new regexp_or_str }
    @stop_words = options.fetch(:stop_words, []).map { |regexp_or_str| StopWord.new regexp_or_str }
    read = options[:read] || options[:haystack_reader]
    @haystack = records.map { |record| Wrapper.new self, record, read }
  end
  
  def last_result
    @last_result || raise(::RuntimeError, "[fuzzy_match] You can't access the last result until you've run a find with :gather_last_result => true")
  end
  
  def find_all(needle, options = {})
    options = options.symbolize_keys.merge(:find_all => true)
    find needle, options
  end
  
  def find(needle, options = {})
    raise ::RuntimeError, "[fuzzy_match] Dictionary has already been freed, can't perform more finds" if freed?
    
    options = options.symbolize_keys
    gather_last_result = options.fetch(:gather_last_result, false)
    is_find_all = options.fetch(:find_all, false)
    first_blocking_decides = options.fetch(:first_blocking_decides, default_first_blocking_decides)
    must_match_blocking = options.fetch(:must_match_blocking, default_must_match_blocking)
    must_match_at_least_one_word = options.fetch(:must_match_at_least_one_word, default_must_match_at_least_one_word)
    
    if gather_last_result
      free_last_result
      @last_result = Result.new
    end
    
    if gather_last_result
      last_result.tighteners = tighteners
      last_result.identities = identities
      last_result.blockings = blockings
      last_result.stop_words = stop_words
    end
    
    needle = Wrapper.new self, needle
    
    if gather_last_result
      last_result.needle = needle
    end
    
    if must_match_blocking and blockings.any? and blockings.none? { |blocking| blocking.match? needle }
      if is_find_all
        return []
      else
        return nil
      end
    end

    candidates = if must_match_at_least_one_word
      haystack.select do |straw|
        (needle.words & straw.words).any?
      end
    else
      haystack
    end
    
    if gather_last_result
      last_result.candidates = candidates
    end
    
    joint, disjoint = if blockings.any?
      candidates.partition do |straw|
        if first_blocking_decides
          blockings.detect { |blocking| blocking.match? needle }.try :join?, needle, straw
        else
          blockings.any? { |blocking| blocking.join? needle, straw }
        end
      end
    else
      [ candidates.dup, [] ]
    end
    
    if joint.none?
      if must_match_blocking
        if is_find_all
          return []
        else
          return nil
        end
      else
        # special case: the needle didn't fit anywhere, but must_match_blocking is false, so we'll try it against everything
        joint = disjoint
        disjoint = []
      end
    end
    
    if gather_last_result
      last_result.joint = joint
      last_result.disjoint = disjoint
    end
    
    possibly_identical, certainly_different = if identities.any?
      joint.partition do |straw|
        identities.all? do |identity|
          answer = identity.identical? needle, straw
          answer.nil? or answer == true
        end
      end
    else
      [ joint.dup, [] ]
    end
    
    if gather_last_result
      last_result.possibly_identical = possibly_identical
      last_result.certainly_different = certainly_different
    end
        
    similarities = possibly_identical.map { |straw| needle.similarity straw }.sort.reverse
        
    if gather_last_result
      last_result.similarities = similarities
    end
    
    if is_find_all
      return similarities.map { |similarity| similarity.wrapper2.record }
    end
    
    if best_similarity = similarities.first and best_similarity.best_score.dices_coefficient_similar > 0
      record = best_similarity.wrapper2.record
      if gather_last_result
        last_result.record = record
        last_result.score = best_similarity.best_score.dices_coefficient_similar
      end
      record
    end
  end
  
  # Explain is like mysql's EXPLAIN command. You give it a needle and it tells you about how it was located (successfully or not) in the haystack.
  #
  #     d = FuzzyMatch.new ['737', '747', '757' ]
  #     d.explain 'boeing 737-100'
  def explain(needle, options = {})
    record = find needle, options.merge(:gather_last_result => true)
    log "#" * 150
    log "# Match #{needle.inspect} => #{record.inspect}"
    log "#" * 150
    log
    log "Needle"
    log "-" * 150
    log last_result.needle.render
    log
    log "Stop words"
    log last_result.stop_words.blank? ? '(none)' : last_result.stop_words.map { |stop_word| stop_word.inspect }.join("\n")
    log
    log "Candidates"
    log "-" * 150
    log last_result.candidates.map { |record| record.render }.join("\n")
    log
    log "Tighteners"
    log "-" * 150
    log last_result.tighteners.blank? ? '(none)' : last_result.tighteners.map { |tightener| tightener.inspect }.join("\n")
    log
    log "Blockings"
    log "-" * 150
    log last_result.blockings.blank? ? '(none)' : last_result.blockings.map { |blocking| blocking.inspect }.join("\n")
    log
    log "Identities"
    log "-" * 150
    log last_result.identities.blank? ? '(none)' : last_result.identities.map { |blocking| blocking.inspect }.join("\n")
    log
    log "Joint"
    log "-" * 150
    log last_result.joint.blank? ? '(none)' : last_result.joint.map { |joint| joint.render }.join("\n")
    log
    log "Disjoint"
    log "-" * 150
    log last_result.disjoint.blank? ? '(none)' : last_result.disjoint.map { |disjoint| disjoint.render }.join("\n")
    log
    log "Possibly identical"
    log "-" * 150
    log last_result.possibly_identical.blank? ? '(none)' : last_result.possibly_identical.map { |possibly_identical| possibly_identical.render }.join("\n")
    log
    log "Certainly different"
    log "-" * 150
    log last_result.certainly_different.blank? ? '(none)' : last_result.certainly_different.map { |certainly_different| certainly_different.render }.join("\n")
    log
    log "Similarities"
    log "-" * 150
    log last_result.similarities.blank? ? '(none)' : last_result.similarities.reverse[0..9].map { |similarity| similarity.inspect }.join("\n")
    log
    log "Match"
    log "-" * 150
    log record.inspect
  end
  
  def log(str = '') #:nodoc:
    $stderr.puts str
  end
    
  def freed?
    @freed == true
  end
  
  def free
    free_last_result
    @haystack.try :clear
    @haystack = nil
  ensure
    @freed = true
  end
  
  private
  
  def free_last_result
    @last_result = nil    
  end
end
