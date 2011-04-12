require 'amatch'

class LooseTightDictionary
  class Score
    attr_reader :str1, :str2

    def initialize(str1, str2)
      @str1 = str1
      @str2 = str2
    end
    
    def to_f
      @to_f ||= str1.pair_distance_similar str2
    end
    
    def inspect
      %{#<Score: to_f=#{to_f}>}
    end
    
    def <=>(other)
      to_f <=> other.to_f
    end
    
    def ==(other)
      to_f == other.to_f
    end
  end
end