class LooseTightDictionary
  # Scorables are the tokens that are passed around when doing scoring and optimizing.
  class Scorable #:nodoc: all
    class << self
      # When you pass two scorables, each of which represents a record (string) from either the needle or the haystack and also all of the "variations" on that string (for example, the end result of a successful tightening),
      # this method uses the "Pair Distance" to generate a numeric score.
      #
      # Sometimes, before performing the final score, the scorables compare notes to determine an appropriate number of characters (a prefix) to compare.
      # This only happens when both scorables are the result of tightenings. Since that indicates they are in their essential form, only the first X characters of each are scored, where X is the length of the shortest scorable.
      # For example, if "737100" and "737" are being compared, "737" will be compared with "737" yielding a perfect score.
      def score(scorable1, scorable2)
        if optimal_prefix_range = scorable1.optimal_prefix_range(scorable2)
          scorable1.to_str[optimal_prefix_range].pair_distance_similar scorable2.to_str[optimal_prefix_range]
        else
          scorable1.to_str.pair_distance_similar scorable2.to_str
        end
      end
    end
    
    attr_reader :parent
    attr_reader :record
    attr_reader :reader
    attr_reader :chosen_tightening
        
    def initialize(attrs = {})
      attrs.each do |k, v|
        instance_variable_set "@#{k}", v
      end
    end

    def tightenings
      parent.tightenings
    end

    def to_str
      if tightened?
        tightened_value
      else
        read_value
      end
    end

    def score(other)
      best_variation, best_other_variation = cart_prod(variations, other.variations).sort_by do |some_variation, some_other_variation|
        Scorable.score some_variation, some_other_variation
      end[-1]
      Scorable.score best_variation, best_other_variation
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
        
    def read_value
      @read_value ||= reader ? reader.call(record) : record.to_s
    end

    def tightened_value
      @tightened_value ||= tightened? ? chosen_tightening.apply(read_value) : read_value
    end

    def tightened?
      !!chosen_tightening
    end

    def variations
      raise RuntimeError, "variations should only be derived from non-tightened records" if tightened?
      tightenings.inject([ self ]) do |memo, tightening|
        if tightening.apply? read_value
          memo.push Scorable.new :parent => parent, :record => record, :reader => reader, :chosen_tightening => tightening
        end
        memo
      end.uniq
    end

    def optimal_prefix_range(other)
      if tightened? and other.tightened?
        0..([ to_str.length, other.to_str.length ].min-1)
      end
    end
  end
end
