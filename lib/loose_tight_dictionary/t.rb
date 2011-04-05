require 'amatch'

class LooseTightDictionary
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
end
