class FuzzyMatch
  class Score
    class PureRuby < Score

      SPACE = ' '

      def inspect
        %{#<FuzzyMatch::Score::PureRuby: str1=#{str1.inspect} str2=#{str2.inspect} dices_coefficient_similar=#{dices_coefficient_similar} levenshtein_similar=#{levenshtein_similar}>}
      end

      # http://stackoverflow.com/questions/653157/a-better-similarity-ranking-algorithm-for-variable-length-strings
      def dices_coefficient_similar
        return @dices_coefficient_similar if @dices_coefficient_similar.is_a?(::Float)
      
        if str1 == str2
          @dices_coefficient_similar = 1.0
          return @dices_coefficient_similar
        elsif str1.length == 1 and str2.length == 1
          @dices_coefficient_similar = 0.0
          return @dices_coefficient_similar
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
        @dices_coefficient_similar = (2.0 * intersection) / union
      end

      # extracted/adapted from the text gem version 1.0.2
      # normalization added for utf-8 strings
      # lib/text/levenshtein.rb
      def levenshtein_similar
        return @levenshtein_similar if @levenshtein_similar.is_a?(::Float)
      
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
          @levenshtein_similar = 0.0
          return @levenshtein_similar
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
        @levenshtein_similar = 1.0 - x.to_f / [n, m].max
      end

      private
    
      def utf8?
        return @utf8_query[0] if @utf8_query.is_a?(::Array) # ActiveSupport::Memoizable is deprecated in 3.2, how annoying
        utf8_query = (defined?(::Encoding) ? str1.encoding.to_s : $KCODE).downcase.start_with?('u')
        @utf8_query = [utf8_query]
        utf8_query
      end
    end
  end
end
