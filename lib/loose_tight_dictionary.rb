require 'amatch'
require 'andand'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/string
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3

class LooseTightDictionary
  class MissedChecks < RuntimeError; end
  class Mismatch < RuntimeError; end
  class FalsePositive < RuntimeError; end

  include Amatch

  attr_reader :left_side_rows, :right_side_rows, :tightenings, :restrictions, :logger

  def initialize(left_side_rows, right_side_rows, tightenings, restrictions, options = {})
    @left_side_rows = left_side_rows
    @right_side_rows = right_side_rows
    @tightenings = tightenings
    @restrictions = restrictions
    @logger = options[:logger]
  end
  
  def check(positives, negatives, log = false)
    seen_positives = Array.new
    seen_negatives = Array.new
    
    left_side_rows.each do |left|
      if p = positives.detect { |p| p[0] == left }
        seen_positives.push p
        correct_right = p[1]
      end
      
      if n = negatives.detect { |n| n[0] == left }
        seen_negatives.push n
        incorrect_right = n[1]
      end

      tightened_left = tighten left
      logger.andand.debug "#{left} (as #{tightened_left})..."
      
      right = left_to_right left
      
      tightened_right = tighten right
      logger.andand.debug "  => #{right} (as #{tightened_right})" if right.present?
      
      if correct_right.present? and right.present? and right != correct_right
        logger.andand.debug "  Mismatch! (should be #{correct_right})"
        raise Mismatch
      end
      
      if incorrect_right.present? and right.present? and right == incorrect_right
        logger.andand.debug "  FALSE POSITIVE! (should NOT be #{incorrect_right})"
        raise FalsePositive
      end
    end
    
    (positives - seen_positives).each do |mc|
      logger.andand.info "  MISSED A CHECK: #{mc.join(' should be ')}"
    end if logger
    
    (negatives - seen_negatives).each do |mc|
      logger.andand.info "  MISSED A CHECK #{mc.join(' should NOT be ')}"
    end if logger
  end
  
  def left_to_right(left)
    lookup left, right_side_rows
  end
  
  def right_to_left(right)
    lookup right, left_side_rows
  end
  
  def lookup(key, against)
    tightened_key = tighten key
    value = against.max do |a, b|
      tightened_a = tighten a
      tightened_b = tighten b
      tightened_a.pair_distance_similar(tightened_key) <=> tightened_b.pair_distance_similar(tightened_key)
    end
    
    restricted_key = restrict key
    restricted_value = restrict value
    
    if restricted_key and restricted_value and restricted_key != restricted_value
      return
    end
    
    value
  end
  
  def restrict(str)
    str = str.to_s.downcase
    restrictions.each do |restriction|
      if restriction.match str
        return $~.captures.compact.join
      end
    end
    nil
  end
    
  def tighten(str)
    str = str.to_s.downcase
    tightenings.each do |tightening|
      if tightening.match str
        return $~.captures.compact.join
      end
    end
    str
  end
end
