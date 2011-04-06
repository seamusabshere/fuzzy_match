require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/string
  active_support/core_ext/hash
  active_support/core_ext/object
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ::ActiveSupport::VERSION::MAJOR == 3

class LooseTightDictionary
  autoload :ExtractRegexp, 'loose_tight_dictionary/extract_regexp'
  autoload :Blocking, 'loose_tight_dictionary/blocking'
  autoload :Identity, 'loose_tight_dictionary/identity'
  autoload :T, 'loose_tight_dictionary/t'
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
    @tightenings ||= (options[:tightenings] || []).map do |i|
      if i.is_a?(::Regexp)
        i
      elsif i.is_a?(::String)
        next if i.blank?
        literal_regexp i
      else
        next if i[0].blank?
        literal_regexp i[0]
      end
    end
  end

  def identities
    @identities ||= (options[:identities] || []).map do |i|
      Identity.new i
    end
  end

  def blockings
    @blockings ||= (options[:blockings] || []).map do |b|
      Blocking.new b
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

    t_map_needle = t_map needle_value
    
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
        
    match = possibly_identical.max do |a_record, b_record|
      a = read_haystack a_record
      b = read_haystack b_record
      
      t_needle_a, t_haystack_a = optimize t_map_needle, t_map(a)
      t_needle_b, t_haystack_b = optimize t_map_needle, t_map(b)
      a_prefix, a_score = t_needle_a.prefix_and_score t_haystack_a
      b_prefix, b_score = t_needle_b.prefix_and_score t_haystack_b

      last_result.register_tt t_needle_a, t_haystack_a, a_prefix, a_score
      last_result.register_tt t_needle_b, t_haystack_b, b_prefix, b_score

      if a_score != b_score
        a_score <=> b_score
      elsif a_prefix and b_prefix and a_prefix != b_prefix
        a_prefix <=> b_prefix
      else
        b.length <=> a.length
      end
    end
    
    value = read_haystack match
    
    last_result.register_match match
    
    match
  end

  def match_with_score(needle)
    match = match needle
    [ match, last_result.score ]
  end

  def optimize(t_map_needle, t_map_haystack)
    cart_prod(t_map_needle, t_map_haystack).max do |a, b|
      t_needle_a, t_haystack_a = a
      t_needle_b, t_haystack_b = b

      a_prefix, a_score = t_needle_a.prefix_and_score t_haystack_a
      b_prefix, b_score = t_needle_b.prefix_and_score t_haystack_b

      last_result.register_tt t_needle_a, t_haystack_a, a_prefix, a_score
      last_result.register_tt t_needle_b, t_haystack_b, b_prefix, b_score

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

  def t_map(str)
    return @t_map[str] if @t_map.try(:has_key?, str)
    @t_map ||= {}
    ary = []
    ary.push T.new(str, str)
    tightenings.each do |regexp|
      if match_data = regexp.match(str)
        ary.push T.new(str, match_data.captures.compact.join)
      end
    end
    @t_map[str] = ary
  end

  def literal_regexp(str)
    return @literal_regexp[str] if @literal_regexp.try(:has_key?, str)
    @literal_regexp ||= {}
    raw_regexp_options = str.split('/').last
    ignore_case = raw_regexp_options.include?('i') ? ::Regexp::IGNORECASE : nil
    multiline = raw_regexp_options.include?('m') ? ::Regexp::MULTILINE : nil
    extended = raw_regexp_options.include?('x') ? ::Regexp::EXTENDED : nil
    @literal_regexp[str] = ::Regexp.new str.gsub(%r{\A/|/([ixm]*)\z}, ''), (ignore_case||multiline||extended)
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
