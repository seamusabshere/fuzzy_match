require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/string
  active_support/core_ext/hash
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ::ActiveSupport::VERSION::MAJOR == 3

class LooseTightDictionary
  autoload :T, 'loose_tight_dictionary/t'
  autoload :I, 'loose_tight_dictionary/i'
  autoload :Result, 'loose_tight_dictionary/result'
  autoload :Improver, 'loose_tight_dictionary/improver'
  
  attr_reader :options
  attr_reader :haystack_records

  def initialize(haystack_records, options = {})
    @options = options.symbolize_keys
    @haystack_records = haystack_records
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
    
  def case_sensitive
    options[:case_sensitive] || false
  end
  
  def blocking_only
    options[:blocking_only] || false
  end

  def tightenings
    @tightenings ||= (options[:tightenings] || []).map do |i|
      next if i[0].blank?
      literal_regexp i[0]
    end
  end

  def identities
    @identities ||= (options[:identities] || []).map do |i|
      next if i[0].blank?
      literal_regexp i[0]
    end
  end

  def blockings
    @blockings ||= (options[:blockings] || []).map do |i|
      next if i[0].blank?
      literal_regexp i[0]
    end
  end
  
  def last_result
    @last_result ||= Result.new
  end
  
  def free_last_result
    @last_result.try :free
    @last_result = nil
  end
  
  def match(needle_record)
    free_last_result
    
    needle = read_needle needle_record

    blocking_needle = blocking needle
    return if blocking_only and blocking_needle.nil?

    i_options_needle = i_options needle
    t_options_needle = t_options needle
    
    # ::Thread.current[:ltd_last_result] = {}
    unblocked, blocked = haystack_records.partition do |haystack_record|
      haystack = read_haystack haystack_record
      blocking_haystack = blocking haystack
      (not blocking_needle and not blocking_haystack) or
        (blocking_haystack and blocking_haystack.match(needle)) or
        (blocking_needle and blocking_needle.match(haystack))
    end
    
    last_result.register_blocked blocked
    last_result.register_unblocked unblocked
    
    haystack_record = unblocked.max do |a_record, b_record|
      a = read_haystack a_record
      b = read_haystack b_record
      i_options_a = i_options a
      i_options_b = i_options b
      collision_a = collision? i_options_needle, i_options_a
      collision_b = collision? i_options_needle, i_options_b
      if collision_a and collision_b
        # neither would ever work, so randomly rank one over the other
        rand(2) == 1 ? -1 : 1
      elsif collision_a
        -1
      elsif collision_b
        1
      else
        t_needle_a, t_haystack_a = optimize t_options_needle, t_options(a)
        t_needle_b, t_haystack_b = optimize t_options_needle, t_options(b)
        a_prefix, a_score = t_needle_a.prefix_and_score t_haystack_a
        b_prefix, b_score = t_needle_b.prefix_and_score t_haystack_b
        last_result.register_score a_record, t_needle_a, t_haystack_a, a_prefix, a_score
        last_result.register_score b_record, t_needle_b, t_haystack_b, b_prefix, b_score

        if a_score != b_score
          a_score <=> b_score
        elsif a_prefix and b_prefix and a_prefix != b_prefix
          a_prefix <=> b_prefix
        else
          b.length <=> a.length
        end
      end
    end
    
    haystack = read_haystack haystack_record
    i_options_haystack = i_options haystack
    return if collision? i_options_needle, i_options_haystack
    
    last_result.register_match haystack_record
    
    haystack_record
  end

  def match_with_score(needle_record)
    match = match needle_record
    [ match, last_result.score ]
  end

  # deprecated
  alias :needle_to_haystack :match

  def optimize(t_options_needle, t_options_haystack)
    cart_prod(t_options_needle, t_options_haystack).max do |a, b|
      t_needle_a, t_haystack_a = a
      t_needle_b, t_haystack_b = b

      a_prefix, a_score = t_needle_a.prefix_and_score t_haystack_a
      b_prefix, b_score = t_needle_b.prefix_and_score t_haystack_b

      if a_score != b_score
        a_score <=> b_score
      elsif a_prefix and b_prefix and a_prefix != b_prefix
        a_prefix <=> b_prefix
      else
        # randomly choose
        # maybe later i can figure out how big the inputs are and apply occam's razor
        rand(2) == 1 ? -1 : 1
      end
    end
  end

  def t_options(str)
    return @t_options[str] if @t_options.try(:has_key?, str)
    @t_options ||= {}
    ary = []
    ary.push T.new(str, str)
    tightenings.each do |regexp|
      if match_data = regexp.match(str)
        ary.push T.new(str, match_data.captures.compact.join)
      end
    end
    @t_options[str] = ary
  end

  def collision?(i_options_needle, i_options_haystack)
    i_options_needle.any? do |r_needle|
      i_options_haystack.any? do |r_haystack|
        r_needle.regexp == r_haystack.regexp and r_needle.identity != r_haystack.identity
      end
    end
  end

  def i_options(str)
    return @i_options[str] if @i_options.try(:has_key?, str)
    @i_options ||= {}
    ary = []
    identities.each do |regexp|
      if regexp.match str
        ary.push I.new(regexp, str, case_sensitive)
      end
    end
    @i_options[str] = ary
  end

  def blocking(str)
    return @blocking[str] if @blocking.try(:has_key?, str)
    @blocking ||= {}
    blockings.each do |regexp|
      if regexp.match str
        return @blocking[str] = regexp
      end
    end
    @blocking[str] = nil
  end

  def literal_regexp(str)
    return @literal_regexp[str] if @literal_regexp.try(:has_key?, str)
    @literal_regexp ||= {}
    raw_regexp_options = str.split('/').last
    ignore_case = (!case_sensitive or raw_regexp_options.include?('i')) ? ::Regexp::IGNORECASE : nil
    multiline = raw_regexp_options.include?('m') ? ::Regexp::MULTILINE : nil
    extended = raw_regexp_options.include?('x') ? ::Regexp::EXTENDED : nil
    @literal_regexp[str] = ::Regexp.new str.gsub(%r{\A/|/([ixm]*)\z}, ''), (ignore_case||multiline||extended)
  end

  def read_needle(needle_record)
    return if needle_record.nil?
    if needle_reader
      needle_reader.call(needle_record)
    elsif needle_record.is_a?(::String)
      case_sensitive ? needle_record : needle_record.downcase
    else
      needle_record[0]
    end
  end

  def read_haystack(haystack_record)
    return if haystack_record.nil?
    if haystack_reader
      haystack_reader.call(haystack_record)
    elsif haystack_record.is_a?(::String)
      case_sensitive ? haystack_record : haystack_record.downcase
    else
      haystack_record[0]
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
