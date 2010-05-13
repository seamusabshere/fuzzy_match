require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/string
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3
require 'amatch'
require 'andand'
require 'fastercsv'

class LooseTightDictionary
  class MissedChecks < RuntimeError; end
  class Mismatch < RuntimeError; end
  class FalsePositive < RuntimeError; end
  
  class T
    attr_reader :str, :tightened_str
    def initialize(str, tightened_str)
      @str = str
      @tightened_str = tightened_str
    end
    
    def tightened?
      str != tightened_str
    end
    
    def prefix_and_score(other)
      prefix = [ tightened_str.length, other.tightened_str.length ].min if tightened? and other.tightened?
      score = if prefix
        tightened_str.first(prefix).pair_distance_similar other.tightened_str.first(prefix)
      else
        tightened_str.pair_distance_similar other.tightened_str
      end
      [ prefix, score ]
    end
  end

  include Amatch

  attr_reader :right_records
  attr_reader :case_sensitive

  attr_accessor :logger
  attr_accessor :tee
  attr_accessor :tee_format  
  attr_accessor :positives
  attr_accessor :negatives
  attr_accessor :left_reader
  attr_accessor :right_reader

  def initialize(right_records, options = {})
    @right_records = right_records
    @_raw_tightenings = options[:tightenings] || Array.new
    @_raw_identities = options[:identities] || Array.new
    @_raw_blockings = options[:blockings] || Array.new
    @left_reader = options[:left_reader]
    @right_reader = options[:right_reader]
    @positives = options[:positives]
    @negatives = options[:negatives]
    @logger = options[:logger]
    @tee = options[:tee]
    @tee_format = options[:tee_format] || :fixed_width
    @case_sensitive = options[:case_sensitive] || false
  end
  
  # def tightenings
  # def identities
  # def blockings
  %w{ tightenings identities blockings }.each do |name|
    module_eval %{
      def #{name}
        @#{name} ||= @_raw_#{name}.map do |i|
          next if i[0].blank?
          literal_regexp i[0]
        end
      end
    }
  end

  def inline_check(left_record, right_record)
    return unless positives.present? or negatives.present?
    
    left = read_left left_record
    right = read_right right_record
    
    if positive_record = positives.andand.detect { |record| record[0] == left }
      correct_right = positive_record[1]
      if correct_right.blank? and right.present?
        logger.andand.debug "  Mismatch! (should match SOMETHING)"
        raise Mismatch
      elsif right != correct_right
        logger.andand.debug "  Mismatch! (should be #{correct_right})"
        raise Mismatch
      end
    end
    
    if negative_record = negatives.andand.detect { |record| record[0] == left }
      incorrect_right = negative_record[1]
      if incorrect_right.blank? and right.present?
        logger.andand.debug "  False positive! (should NOT match ANYTHING)"
        raise FalsePositive
      elsif right == incorrect_right
        logger.andand.debug "  False positive! (should NOT be #{incorrect_right})"
        raise FalsePositive
      end
    end
  end

  def check(left_records)
    header = [ 'Left record (input)', 'Right record (output)', 'Prefix used (if any)', 'Score' ]
    case tee_format
    when :csv
      tee.andand.puts header.flatten.to_csv
    when :fixed_width
      tee.andand.puts header.map { |i| i.to_s.ljust(30) }.join
    end

    left_records.each do |left_record|
      begin
        right_record = left_to_right left_record
      ensure
        case tee_format
        when :csv
          tee.andand.puts $ltd_1.flatten.to_csv
        when :fixed_width
          tee.andand.puts $ltd_1.map { |i| i.to_s.ljust(30) }.join if $ltd_1
        end
      end
    end
  end
  
  def left_to_right(left_record)
    left = read_left left_record
    i_options_left = i_options left
    blocking_left = blocking left
    t_options_left = t_options left
    history = Hash.new
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
        history[a_record] = [t_left_a.tightened_str, t_right_a.tightened_str, a_prefix ? a_prefix : 'NULL', a_score]
        history[b_record] = [t_left_b.tightened_str, t_right_b.tightened_str, b_prefix ? b_prefix : 'NULL', b_score]
        
        yep_dd = ($ltd_dd_right and $ltd_dd_left and [t_left_a, t_left_b].any? { |f| f.str =~ $ltd_dd_left } and [t_right_a, t_right_b].any? { |f| f.str =~ $ltd_dd_right } and (!$ltd_dd_left_not or [t_left_a, t_left_b].none? { |f| f.str =~ $ltd_dd_left_not }))
        
        if $ltd_dd_print and yep_dd
          logger.andand.debug t_left_a.inspect
          logger.andand.debug t_right_a.inspect
          logger.andand.debug t_left_b.inspect
          logger.andand.debug t_right_b.inspect
          logger.andand.debug
        end

        z = 1
        debugger if yep_dd
        z = 1
        
        if a_score != b_score
          a_score <=> b_score
        elsif a_prefix and b_prefix and a_prefix != b_prefix
          a_prefix <=> b_prefix
        else
          b.length <=> a.length
        end
      end
    end
    $ltd_1 = history[right_record]
    right = read_right right_record
    i_options_right = i_options right
    z = 1
    debugger if $ltd_left.andand.match(left) or $ltd_right.andand.match(right)
    z = 1
    if collision? i_options_left, i_options_right
      $ltd_0 = nil
      return
    else
      $ltd_0 = right_record
    end
    inline_check left_record, right_record
    right_record
  end
  
  def optimize(t_options_left, t_options_right)
    cart_prod(t_options_left, t_options_right).max do |a, b|
      t_left_a, t_right_a = a
      t_left_b, t_right_b = b
    
      a_prefix, a_score = t_left_a.prefix_and_score t_right_a
      b_prefix, b_score = t_left_b.prefix_and_score t_right_b
      
      yep_ddd = ($ltd_ddd_right and $ltd_ddd_left and [t_left_a, t_left_b].any? { |f| f.str =~ $ltd_ddd_left } and [t_right_a, t_right_b].any? { |f| f.str =~ $ltd_ddd_right } and (!$ltd_ddd_left_not or [t_left_a, t_left_b].none? { |f| f.str =~ $ltd_ddd_left_not }))
      
      if $ltd_ddd_print and yep_ddd
        logger.andand.debug t_left_a.inspect
        logger.andand.debug t_right_a.inspect
        logger.andand.debug t_left_b.inspect
        logger.andand.debug t_right_b.inspect
        logger.andand.debug
      end
      
      z = 1
      debugger if yep_ddd
      z = 1
      
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
    return @_t_options[str] if @_t_options.andand.has_key?(str)
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
  
  class I
    attr_reader :regexp, :str, :case_sensitive, :identity
    def initialize(regexp, str, case_sensitive)
      @regexp = regexp
      @str = str
      @identity = regexp.match(str).captures.compact.join
      @identity = @identity.downcase if case_sensitive
    end
  end
  
  def collision?(i_options_left, i_options_right)
    i_options_left.any? do |r_left|
      i_options_right.any? do |r_right|
        r_left.regexp == r_right.regexp and r_left.identity != r_right.identity
      end
    end
  end
  
  def i_options(str)
    return @_i_options[str] if @_i_options.andand.has_key?(str)
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
    return @_blocking[str] if @_blocking.andand.has_key?(str)
    @_blocking ||= Hash.new
    blockings.each do |regexp|
      if regexp.match str
        return @_blocking[str] = regexp
      end
    end
    @_blocking[str] = nil
  end
  
  def literal_regexp(str)
    return @_literal_regexp[str] if @_literal_regexp.andand.has_key? str
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
