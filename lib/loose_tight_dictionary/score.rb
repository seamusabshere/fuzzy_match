begin
  require 'amatch'
rescue ::LoadError
  # using native ruby similarity scoring
end

class LooseTightDictionary
  class Score
    attr_reader :str1, :str2

    def initialize(str1, str2)
      @str1 = str1
      @str2 = str2
    end
    
    def to_f
      @to_f ||= dices_coefficient(str1, str2)
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
    
    private
    
    # http://stackoverflow.com/questions/653157/a-better-similarity-ranking-algorithm-for-variable-length-strings
    if defined?(::Amatch)
      def dices_coefficient(str1, str2)
        str1 = str1.downcase 
        str2 = str2.downcase
        str1.pair_distance_similar str2
      end
    else
      SPACE = ' '
      def dices_coefficient(str1, str2)
        str1 = str1.downcase 
        str2 = str2.downcase
        if str1 == str2
          return 1.0
        elsif str1.length == 1 and str2.length == 1
          return 0.0
        end
        pairs1 = (0..str1.length-2).map do |i|
          str1[i,2]
        end.reject do |pair|
          pair.include? SPACE
        end
        pairs2 = (0..str2.length-2).map do |i|
          str2[i,2]
        end.reject do |pair|
          pair.include? SPACE
        end
        union = pairs1.size + pairs2.size 
        intersection = 0 
        pairs1.each do |p1| 
          0.upto(pairs2.size-1) do |i| 
            if p1 == pairs2[i] 
              intersection += 1 
              pairs2.slice!(i) 
              break 
            end 
          end 
        end 
        (2.0 * intersection) / union
      end
    end
  end
end