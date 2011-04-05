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
  autoload :Improver, 'loose_tight_dictionary/improver'
  
  attr_reader :options
  attr_reader :right_records

  def initialize(right_records, options = {})
    @options = options.symbolize_keys
    @right_records = right_records
  end
  
  def improver
    @improver ||= Improver.new self
  end
  
  def left_reader
    options[:left_reader]
  end
  
  def right_reader
    options[:right_reader]
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

  def blocking_only?
    !!blocking_only
  end

  def log(str = '')
    options[:log].puts str if options[:log]
  end
  
  def tee(str = '')
    options[:tee].puts str if options[:tee]
  end

  def find(left_record)
    left = read_left left_record
    blocking_left = blocking left
    return if blocking_only? and blocking_left.nil?
    i_options_left = i_options left
    t_options_left = t_options left
    ::Thread.current[:ltd_last_run] = {}
    right_record = right_records.select do |right_record|
      right = read_right right_record
      blocking_right = blocking right
      (not blocking_left and not blocking_right) or
        (blocking_right and blocking_right.match(left)) or
        (blocking_left and blocking_left.match(right))
    end.max do |a_record, b_record|
      a = read_right a_record
      b = read_right b_record
      i_options_a = i_options a
      i_options_b = i_options b
      collision_a = collision? i_options_left, i_options_a
      collision_b = collision? i_options_left, i_options_b
      if collision_a and collision_b
        # neither would ever work, so randomly rank one over the other
        rand(2) == 1 ? -1 : 1
      elsif collision_a
        -1
      elsif collision_b
        1
      else
        t_left_a, t_right_a = optimize t_options_left, t_options(a)
        t_left_b, t_right_b = optimize t_options_left, t_options(b)
        a_prefix, a_score = t_left_a.prefix_and_score t_right_a
        b_prefix, b_score = t_left_b.prefix_and_score t_right_b
        ::Thread.current[:ltd_last_run][a_record] = [t_left_a.tightened_str, t_right_a.tightened_str, a_prefix ? a_prefix : 'NULL', a_score]
        ::Thread.current[:ltd_last_run][b_record] = [t_left_b.tightened_str, t_right_b.tightened_str, b_prefix ? b_prefix : 'NULL', b_score]

        if a_score != b_score
          a_score <=> b_score
        elsif a_prefix and b_prefix and a_prefix != b_prefix
          a_prefix <=> b_prefix
        else
          b.length <=> a.length
        end
      end
    end
    right = read_right right_record
    i_options_right = i_options right
    return if collision? i_options_left, i_options_right
    right_record
  end

  # deprecated
  alias :left_to_right :find

  def optimize(t_options_left, t_options_right)
    cart_prod(t_options_left, t_options_right).max do |a, b|
      t_left_a, t_right_a = a
      t_left_b, t_right_b = b

      a_prefix, a_score = t_left_a.prefix_and_score t_right_a
      b_prefix, b_score = t_left_b.prefix_and_score t_right_b

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
    return @_t_options[str] if @_t_options.try(:has_key?, str)
    @_t_options ||= Hash.new
    ary = Array.new
    ary.push T.new(str, str)
    tightenings.each do |regexp|
      if match_data = regexp.match(str)
        ary.push T.new(str, match_data.captures.compact.join)
      end
    end
    @_t_options[str] = ary
  end

  def collision?(i_options_left, i_options_right)
    i_options_left.any? do |r_left|
      i_options_right.any? do |r_right|
        r_left.regexp == r_right.regexp and r_left.identity != r_right.identity
      end
    end
  end

  def i_options(str)
    return @_i_options[str] if @_i_options.try(:has_key?, str)
    @_i_options ||= Hash.new
    ary = Array.new
    identities.each do |regexp|
      if regexp.match str
        ary.push I.new(regexp, str, case_sensitive)
      end
    end
    @_i_options[str] = ary
  end

  def blocking(str)
    return @_blocking[str] if @_blocking.try(:has_key?, str)
    @_blocking ||= Hash.new
    blockings.each do |regexp|
      if regexp.match str
        return @_blocking[str] = regexp
      end
    end
    @_blocking[str] = nil
  end

  def literal_regexp(str)
    return @_literal_regexp[str] if @_literal_regexp.try(:has_key?, str)
    @_literal_regexp ||= Hash.new
    raw_regexp_options = str.split('/').last
    ignore_case = (!case_sensitive or raw_regexp_options.include?('i')) ? Regexp::IGNORECASE : nil
    multiline = raw_regexp_options.include?('m') ? Regexp::MULTILINE : nil
    extended = raw_regexp_options.include?('x') ? Regexp::EXTENDED : nil
    @_literal_regexp[str] = Regexp.new str.gsub(/\A\/|\/([ixm]*)\z/, ''), (ignore_case||multiline||extended)
  end

  def read_left(left_record)
    return if left_record.nil?
    if left_reader
      left_reader.call(left_record)
    elsif left_record.is_a?(String)
      left_record
    else
      left_record[0]
    end
  end

  def read_right(right_record)
    return if right_record.nil?
    if right_reader
      right_reader.call(right_record)
    elsif right_record.is_a?(String)
      right_record
    else
      right_record[0]
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
