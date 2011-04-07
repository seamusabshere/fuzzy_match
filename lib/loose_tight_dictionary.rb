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
  autoload :Result, 'loose_tight_dictionary/result'
  autoload :Improver, 'loose_tight_dictionary/improver'
  
  attr_reader :options
  attr_reader :haystack

  def initialize(haystack, options = {})
    @options = options.symbolize_keys
    @haystack = haystack
  end
  
  def improver
    @improver ||= Improver.new self
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
  
  def last_result
    @last_result ||= Result.new
  end
  
  def free_last_result
    @last_result.try :free
    @last_result = nil
  end
  
  def match(needle)
    free_last_result
    
    needle_value = read_needle needle

    return if strict_blocking and blockings.none? { |blocking| blocking.encompass? needle_value }

    encompassed, unencompassed = if strict_blocking and blockings.any?
      haystack.partition do |record|
        value = read_haystack record
        blockings.any? do |blocking|
          blocking.encompass? needle_value, value
        end
      end
    else
      [ haystack.dup, [] ]
    end
    
    last_result.encompassed = encompassed
    last_result.unencompassed = unencompassed
    
    possibly_identical, certainly_different = if identities.any?
      encompassed.partition do |record|
        value = read_haystack record
        identities.all? do |identity|
          identity.possibly_identical? needle_value, value
        end
      end
    else
      [ encompassed.dup, [] ]
    end
        
    needle_variations = vary needle_value
    
    scores = possibly_identical.inject({}) do |memo, record|
      value = read_haystack record
      variations = vary value
      best_tuple = cart_prod(needle_variations, variations).sort_by do |needle_value_1, value_1|
        score needle_value_1, value_1
      end[-1]
      memo[record] = score(best_tuple[0], best_tuple[1])
      memo
    end
    
    match, score = scores.max do |a, b|
      _, score_a = a
      _, score_b = b
      score_a <=> score_b
    end

    last_result.score = score
    last_result.match = match
        
    match
  end

  def vary(str)
    tightenings.inject([ str ]) do |memo, tightening|
      memo.push tightening.apply(str)
      memo
    end.uniq
  end
  
  def score(needle_value, value)
    needle_value.pair_distance_similar value
  end

  def match_with_score(needle)
    match = match needle
    [ match, last_result.score ]
  end

  def read_needle(needle)
    return if needle.nil?
    if needle_reader
      needle_reader.call(needle)
    elsif needle.is_a?(::String)
      needle
    else
      needle[0]
    end
  end

  def read_haystack(record)
    return if record.nil?
    if haystack_reader
      haystack_reader.call(record)
    elsif record.is_a?(::String)
      record
    else
      record[0]
    end
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
