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

  attr_reader :left_side_rows
  attr_reader :right_side_rows
  attr_reader :tightenings
  attr_reader :restrictions
  attr_reader :logger
  attr_reader :tee
  attr_reader :case_sensitive
  
  attr_accessor :left_reader
  attr_accessor :right_reader

  def initialize(left_side_rows, right_side_rows, tightenings, restrictions, options = {})
    @left_side_rows = left_side_rows
    @right_side_rows = right_side_rows
    @tightenings = tightenings
    @restrictions = restrictions
    @logger = options[:logger]
    @tee = options[:tee]
    @case_sensitive = options[:case_sensitive] || false
  end

  def check(positives, negatives, log = false)
    seen_positives = Array.new
    
    left_side_rows.each do |row|
      left = read_left row
      
      if p = positives.detect { |p| p[0] == left }
        seen_positives.push p[0]
        correct_right = p[1]
      end
      
      incorrect_right = negatives.detect { |n| n[0] == left }.andand[1]

      right = left_to_right left
      
      if correct_right.present? and right.present? and right != correct_right
        logger.andand.debug "  Mismatch! (should be #{correct_right})"
        raise Mismatch
      end
      
      if incorrect_right.present? and right.present? and right == incorrect_right
        logger.andand.debug "  FALSE POSITIVE! (should NOT be #{incorrect_right})"
        raise FalsePositive
      end
    end
    
    positives.reject { |p| seen_positives.include? p[0] }.each do |miss|
      logger.andand.info "  MISSED POSITIVE: #{miss[0]} should be #{miss[1]}"
    end
  end
  
  def left_to_right(left)
    restricted_left = restrict left
    t_options_left = t_options left
    
    guess_row = right_side_rows.max do |a_row, b_row|
      a = read_right a_row
      b = read_right b_row
      
      restricted_a = restrict a
      restricted_b = restrict b
      
      if restricted_left and restricted_a and restricted_b and restricted_left != restricted_a and restricted_left != restricted_b
        # neither would ever work, so randomly rank one over the other
        rand(2) == 1 ? -1 : 1
      elsif restricted_left and restricted_a and restricted_left != restricted_a
        -1
      elsif restricted_left and restricted_b and restricted_left != restricted_b
        1
      else
        t_left_a, t_a = optimize t_options_left, t_options(a)
        t_left_b, t_b = optimize t_options_left, t_options(b)

        a_prefix, a_score = t_left_a.prefix_and_score t_a
        b_prefix, b_score = t_left_b.prefix_and_score t_b

        if a_score != b_score
          a_score <=> b_score
        elsif a_prefix and b_prefix and a_prefix != b_prefix
          a_prefix <=> b_prefix
        else
          b.length <=> a.length
        end
      end
    end
    
    guess = read_right guess_row
    
    restricted_guess = restrict guess
    
    if restricted_left and restricted_guess and restricted_left != restricted_guess
      return
    end
    
    guess
  ensure
    tee.andand.puts [ left, guess ].to_csv
  end
  
  def optimize(t_options_x, t_options_y)
    cart_prod(t_options_x, t_options_y).max do |a, b|
      t_x_a, t_y_a = a
      t_x_b, t_y_b = b
    
      a_prefix, a_score = t_x_a.prefix_and_score t_y_a
      b_prefix, b_score = t_x_b.prefix_and_score t_y_b
            
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
    ary << T.new(str, str)
    tightenings.each do |tightening|
      if literal_regexp(tightening[0]).match str
        ary << T.new(str, $~.captures.compact.join)
      end
    end
    @_t_options[str] = ary
  end
  
  def restrict(str)
    return @_restrict[str] if @_restrict.andand.has_key?(str)
    @_restrict ||= Hash.new
    restrictions.each do |restriction|
      if literal_regexp(restriction[0]).match str
        retval = $~.captures.compact.join
        retval = retval.downcase unless case_sensitive
        return @_restrict[str] = retval
      end
    end
    @_restrict[str] = nil
  end
  
  def literal_regexp(str)
    return @_literal_regexp[str] if @_literal_regexp.andand.has_key? str
    @_literal_regexp ||= Hash.new
    raw_regexp_options = str.split('/').last
    i = (!case_sensitive or raw_regexp_options.include?('i')) ? Regexp::IGNORECASE : nil
    m = raw_regexp_options.include?('m') ? Regexp::MULTILINE : nil
    x = raw_regexp_options.include?('x') ? Regexp::EXTENDED : nil
    @_literal_regexp[str] = Regexp.new str.gsub(/\A\/|\/([ixm]*)\z/, ''), (i||m||x), 'U'
  end
  
  def read_left(row)
    left_reader ? left_reader.call(row) : row[0]
  end
  
  def read_right(row)
    right_reader ? right_reader.call(row) : row[0]
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
