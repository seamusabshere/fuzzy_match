begin
  require 'amatch'
rescue ::LoadError
  # using native ruby similarity scoring
end

class FuzzyMatch
  class Score
    attr_reader :str1, :str2

    def initialize(str1, str2)
      @str1 = str1.downcase
      @str2 = str2.downcase
    end
    
    def inspect
      %{#<Score: dices_coefficient=#{dices_coefficient} levenshtein=#{levenshtein}>}
    end
    
    def <=>(other)
      by_dices_coefficient = (dices_coefficient <=> other.dices_coefficient)
      if by_dices_coefficient == 0
        levenshtein <=> other.levenshtein
      else
        by_dices_coefficient
      end
    end
        
    def utf8?
      (defined?(::Encoding) ? str1.encoding.to_s : $KCODE).downcase.start_with?('u')
    end
    
    if defined?(::Amatch)
      
      def dices_coefficient
        str1.pair_distance_similar str2
      end
      
      def levenshtein
        str1.levenshtein_similar str2
      end
      
    else
      
      SPACE = ' '
      # http://stackoverflow.com/questions/653157/a-better-similarity-ranking-algorithm-for-variable-length-strings
      def dices_coefficient
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

      # extracted/adapted from the text gem version 1.0.2
      # normalization added for utf-8 strings
      # lib/text/levenshtein.rb
      def levenshtein
        if utf8?
          unpack_rule = 'U*'
        else
          unpack_rule = 'C*'
        end
        s = str1.unpack(unpack_rule)
        t = str2.unpack(unpack_rule)
        n = s.length
        m = t.length
        if n == 0 or m == 0
          return 0.0
        end
        d = (0..m).to_a
        x = nil
        (0...n).each do |i|
          e = i+1
          (0...m).each do |j|
            cost = (s[i] == t[j]) ? 0 : 1
            x = [
              d[j+1] + 1, # insertion
              e + 1,      # deletion
              d[j] + cost # substitution
            ].min
            d[j] = e
            e = x
          end
          d[m] = x
        end
        # normalization logic from https://github.com/flori/amatch/blob/master/ext/amatch_ext.c#L301
        # if (b_len > a_len) {
        #     result = rb_float_new(1.0 - ((double) v[p][b_len]) / b_len);
        # } else {
        #     result = rb_float_new(1.0 - ((double) v[p][b_len]) / a_len);
        # }
        1.0 - x.to_f / [n, m].max
      end
      
    end
    
    extend ::ActiveSupport::Memoizable
    memoize :dices_coefficient
    memoize :levenshtein
    memoize :utf8?
  end
end