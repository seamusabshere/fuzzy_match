require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/string
  active_support/core_ext/hash
  active_support/core_ext/object
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ::ActiveSupport::VERSION::MAJOR == 3
require 'amatch'

class LooseTightDictionary
  autoload :ExtractRegexp, 'loose_tight_dictionary/extract_regexp'
  autoload :Tightening, 'loose_tight_dictionary/tightening'
  autoload :Blocking, 'loose_tight_dictionary/blocking'
  autoload :Identity, 'loose_tight_dictionary/identity'
  autoload :Record, 'loose_tight_dictionary/record'
  autoload :Result, 'loose_tight_dictionary/result'
  autoload :Improver, 'loose_tight_dictionary/improver'
  
  attr_reader :options
  attr_reader :haystack

  def initialize(haystack, options = {})
    @options = options.symbolize_keys
    @haystack = haystack.map { |record| Record.wrap record, haystack_reader, tightenings }
  end
  
  def improver
    @improver ||= Improver.new self
  end
  
  def last_result
    @last_result ||= Result.new
  end
  
  def match_with_score(needle)
    match = match needle
    [ match, last_result.score ]
  end
  
  def match(needle)
    free_last_result
    
    needle = Record.wrap needle, needle_reader, tightenings
    
    return if strict_blocking and blockings.none? { |blocking| blocking.encompass? needle }

    encompassed, unencompassed = if strict_blocking and blockings.any?
      haystack.partition do |record|
        blockings.any? do |blocking|
          blocking.encompass?(needle, record) == true
        end
      end
    else
      [ haystack.dup, [] ]
    end
    
    last_result.encompassed = encompassed
    last_result.unencompassed = unencompassed
    
    possibly_identical, certainly_different = if identities.any?
      encompassed.partition do |record|
        identities.all? do |identity|
          answer = identity.identical? needle, record
          answer.nil? or answer == true
        end
      end
    else
      [ encompassed.dup, [] ]
    end
    
    last_result.possibly_identical = possibly_identical
    last_result.certainly_different = certainly_different
        
    scores = possibly_identical.inject({}) do |memo, record|
      best_needle_interpretation, best_record_interpretation = cart_prod(needle.ltd_interpretations, record.ltd_interpretations).sort_by do |needle_1, record_1|
        record_1.ltd_score needle_1
      end[-1]
      memo[record] = best_record_interpretation.ltd_score best_needle_interpretation
      memo
    end
    
    last_result.scores = scores
    
    match, score = scores.max do |a, b|
      _, score_a = a
      _, score_b = b
      score_a <=> score_b
    end

    last_result.score = score
    last_result.match = match
        
    match.ltd_unwrap
  end
  
  def needle_reader
    options[:needle_reader]
  end
  
  def haystack_reader
    options[:haystack_reader]
  end
        
  def strict_blocking
    options[:strict_blocking] || false
  end

  def tightenings
    @tightenings ||= (options[:tightenings] || []).map do |regexp_or_str|
      Tightening.new regexp_or_str
    end
  end

  def identities
    @identities ||= (options[:identities] || []).map do |regexp_or_str|
      Identity.new regexp_or_str
    end
  end

  def blockings
    @blockings ||= (options[:blockings] || []).map do |regexp_or_str|
      Blocking.new regexp_or_str
    end
  end
  
  private
  
  def free_last_result
    @last_result.try :free
    @last_result = nil
  end

  # Thanks William James!
  # http://www.ruby-forum.com/topic/95519#200484
  def cart_prod(*args)
    args.inject([[]]){|old,lst|
      new = []
      lst.each{|e| new += old.map{|c| c.dup << e }}
      new
    }
  end
end
