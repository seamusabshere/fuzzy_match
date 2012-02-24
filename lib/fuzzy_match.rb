require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR >= 3
  require 'active_support/core_ext'
end
require 'to_regexp'

require 'fuzzy_match/normalizer'
require 'fuzzy_match/stop_word'
require 'fuzzy_match/grouping'
require 'fuzzy_match/identity'
require 'fuzzy_match/result'
require 'fuzzy_match/wrapper'
require 'fuzzy_match/similarity'
require 'fuzzy_match/score'

if defined?(::ActiveRecord)
  require 'fuzzy_match/cached_result'
end

# See the README for more information.
class FuzzyMatch
  class << self
    def engine
      @@engine ||= :pure_ruby
    end
    
    def engine=(alt_engine)
      @@engine = alt_engine
    end
    
    def score_class
      case engine
      when :pure_ruby
        Score::PureRuby
      when :amatch
        Score::Amatch
      else
        raise ::ArgumentError, "[fuzzy_match] #{engine.inspect} is not a recognized engine."
      end
    end
  end
  
  DEFAULT_ENGINE = :pure_ruby
  
  DEFAULT_OPTIONS = {
    :first_grouping_decides => false,
    :must_match_grouping => false,
    :must_match_at_least_one_word => false,
    :gather_last_result => false,
    :find_all => false
  }
  
  attr_reader :haystack
  attr_reader :groupings
  attr_reader :identities
  attr_reader :normalizers
  attr_reader :stop_words
  attr_reader :read
  attr_reader :default_options

  # haystack - a bunch of records that will compete to see who best matches the needle
  #
  # Rules (can only be specified at initialization or by using a setter)
  # * :<tt>normalizers</tt> - regexps (see README)
  # * :<tt>identities</tt> - regexps
  # * :<tt>groupings</tt> - regexps
  # * :<tt>stop_words</tt> - regexps
  #
  # Options (can be specified at initialization or when calling #find)
  # * :<tt>read</tt> - how to interpret each record in the 'haystack', either a Proc or a symbol
  # * :<tt>must_match_grouping</tt> - don't return a match unless the needle fits into one of the groupings you specified
  # * :<tt>must_match_at_least_one_word</tt> - don't return a match unless the needle shares at least one word with the match
  # * :<tt>first_grouping_decides</tt> - force records into the first grouping they match, rather than choosing a grouping that will give them a higher score
  # * :<tt>gather_last_result</tt> - enable <tt>last_result</tt>
  def initialize(competitors, options_and_rules = {})
    options_and_rules = options_and_rules.symbolize_keys

    # rules
    self.groupings = options_and_rules.delete(:groupings) || options_and_rules.delete(:blockings) || []
    self.identities = options_and_rules.delete(:identities) || []
    self.normalizers = options_and_rules.delete(:normalizers) || options_and_rules.delete(:tighteners) || []
    self.stop_words = options_and_rules.delete(:stop_words) || []
    @read = options_and_rules.delete(:read) || options_and_rules.delete(:haystack_reader)

    # options
    if deprecated = options_and_rules.delete(:first_blocking_decides)
      options_and_rules[:first_grouping_decides] = deprecated
    end
    if deprecated = options_and_rules.delete(:must_match_blocking)
      options_and_rules[:must_match_grouping] = deprecated
    end
    @default_options = options_and_rules.reverse_merge(DEFAULT_OPTIONS).freeze

    # do this last
    self.haystack = competitors
  end
  
  def groupings=(ary)
    @groupings = ary.map { |regexp_or_str| Grouping.new regexp_or_str }
  end
  
  def identities=(ary)
    @identities = ary.map { |regexp_or_str| Identity.new regexp_or_str }
  end
  
  def normalizers=(ary)
    @normalizers = ary.map { |regexp_or_str| Normalizer.new regexp_or_str }
  end
  
  def stop_words=(ary)
    @stop_words = ary.map { |regexp_or_str| StopWord.new regexp_or_str }
  end
  
  def haystack=(ary)
    @haystack = ary.map { |competitor| Wrapper.new self, competitor }
  end
  
  def last_result
    @last_result || raise(::RuntimeError, "[fuzzy_match] You can't access the last result until you've run a find with :gather_last_result => true")
  end
  
  def find_all(needle, options = {})
    options = options.symbolize_keys.merge(:find_all => true)
    find needle, options
  end
  
  def find(needle, options = {})
    options = options.symbolize_keys.reverse_merge default_options
    
    gather_last_result = options[:gather_last_result]
    is_find_all = options[:find_all]
    first_grouping_decides = options[:first_grouping_decides]
    must_match_grouping = options[:must_match_grouping]
    must_match_at_least_one_word = options[:must_match_at_least_one_word]
    
    if gather_last_result
      @last_result = Result.new
      last_result.read = read
      last_result.haystack = haystack
      last_result.options = options
      last_result.timeline << <<-EOS
Options were set, either by you or by falling back to defaults.
\tOptions: #{options.inspect}
EOS
    end
    
    if gather_last_result
      last_result.normalizers = normalizers
      last_result.identities = identities
      last_result.groupings = groupings
      last_result.stop_words = stop_words
    end
    
    needle = Wrapper.new self, needle, true
    
    if gather_last_result
      last_result.needle = needle
      last_result.timeline << <<-EOS
The needle's #{needle.variants.length} variants were enumerated.
\tVariants: #{needle.variants.map(&:inspect).join(', ')}
EOS
    end
    
    if must_match_grouping and groupings.any? and groupings.none? { |grouping| grouping.match? needle }
      if gather_last_result
        last_result.timeline << <<-EOS
The needle didn't match any of the #{groupings.length} grouping, which was a requirement.
\tGroupings (first 3): #{groupings[0,3].map(&:inspect).join(', ')}
EOS
      end
      
      if is_find_all
        return []
      else
        return nil
      end
    end

    if must_match_at_least_one_word
      passed_word_requirement = haystack.select do |straw|
        (needle.words & straw.words).any?
      end
      if gather_last_result
        last_result.timeline << <<-EOS
Since :must_match_at_least_one_word => true, the competition was reduced to records sharing at least one word with the needle.
\tNeedle words: #{needle.words.map(&:inspect).join(', ')}
\tPassed (first 3): #{passed_word_requirement[0,3].map(&:render).map(&:inspect).join(', ')}
\tFailed (first 3): #{(haystack-passed_word_requirement)[0,3].map(&:render).map(&:inspect).join(', ')}
EOS
      end
    else
      passed_word_requirement = haystack
    end
    
    if groupings.any?
      joint = passed_word_requirement.select do |straw|
        if first_grouping_decides
          groupings.detect { |grouping| grouping.match? needle }.try :join?, needle, straw
        else
          groupings.any? { |grouping| grouping.join? needle, straw }
        end
      end
      if gather_last_result
        last_result.timeline << <<-EOS
Since there were groupings, the competition was reduced to records in the same group as the needle.
\tGroupings (first 3): #{groupings[0,3].map(&:inspect).join(', ')}
\tPassed (first 3): #{joint[0,3].map(&:render).map(&:inspect).join(', ')}
\tFailed (first 3): #{(passed_word_requirement-joint)[0,3].map(&:render).map(&:inspect).join(', ')}
EOS
      end
    else
      joint = passed_word_requirement.dup
    end
    
    if joint.none?
      if must_match_grouping
        if gather_last_result
          last_result.timeline << <<-EOS
Since :must_match_at_least_one_word => true and none of the competition was in the same group as the needle, the search stopped.
EOS
        end
        if is_find_all
          return []
        else
          return nil
        end
      else
        joint = passed_word_requirement.dup
      end
    end
        
    if identities.any?
      possibly_identical = joint.select do |straw|
        identities.all? do |identity|
          answer = identity.identical? needle, straw
          answer.nil? or answer == true
        end
      end
      if gather_last_result
        last_result.timeline << <<-EOS
Since there were identities, the competition was reduced to records that might be identical to the needle (in other words, are not certainly different)
\Identities (first 3): #{identities[0,3].map(&:inspect).join(', ')}
\tPassed (first 3): #{possibly_identical[0,3].map(&:render).map(&:inspect).join(', ')}
\tFailed (first 3): #{(joint-possibly_identical)[0,3].map(&:render).map(&:inspect).join(', ')}
EOS
      end
    else
      possibly_identical = joint.dup
    end
        
    similarities = possibly_identical.map { |straw| needle.similarity straw }.sort.reverse
        
    if gather_last_result
        last_result.timeline << <<-EOS
The competition was sorted in order of similarity to the needle.
\tSimilar (first 3): #{(similarities)[0,3].map(&:wrapper2).map(&:render).map(&:inspect).join(', ')}
EOS
    end
    
    if is_find_all
      return similarities.map { |similarity| similarity.wrapper2.record }
    end
    
    winner = nil

    if best_similarity = similarities.first and (best_similarity.best_score.dices_coefficient_similar > 0 or best_similarity.best_score.levenshtein_similar > 0)
      winner = best_similarity.wrapper2.record
      if gather_last_result
        last_result.winner = winner
        last_result.score = best_similarity.best_score.dices_coefficient_similar
        last_result.timeline << <<-EOS
A winner was determined because the Dice's Coefficient similarity (#{best_similarity.best_score.dices_coefficient_similar}) or the Levenshtein similarity (#{best_similarity.best_score.levenshtein_similar}) is greater than zero.
EOS
      end
    elsif gather_last_result
        last_result.timeline << <<-EOS
No winner assigned because similarity score was zero.
EOS
    end
    
    winner
  end
  
  # Explain is like mysql's EXPLAIN command. You give it a needle and it tells you about how it was located (successfully or not) in the haystack.
  #
  #     d = FuzzyMatch.new ['737', '747', '757' ]
  #     d.explain 'boeing 737-100'
  def explain(needle, options = {})
    find needle, options.merge(:gather_last_result => true)
    last_result.explain
  end

  # DEPRECATED
  def free
  end
end
