class FuzzyMatch
  class Score
    class PureRuby < Score

      SPACE = ' '

      # http://stackoverflow.com/questions/653157/a-better-similarity-ranking-algorithm-for-variable-length-strings
      def dices_coefficient_similar
        return 1.0 if str1 == str2
        @dices_coefficient_similar ||= begin
          pair_sets    = [str1, str2].map { |str| split_as_bigrams(str) }
          union        = pair_sets.map(&:size).reduce(:+)
          intersection = 0

          pair_sets[0].each do |pair|
            if (i = pair_sets[1].index(pair))
              intersection += 1
              pair_sets[1].slice!(i)
            end
          end

          (2.0 * intersection) / union
        end
      end

      # extracted/adapted from the text gem version 1.0.2
      # normalization added for utf-8 strings
      # lib/text/levenshtein.rb
      def levenshtein_similar
        @levenshtein_similar ||= begin
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
            0.0
          else
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
      end

      private
    
      def utf8?
        return @utf8_query if defined?(@utf8_query)
        @utf8_query = (defined?(::Encoding) ? str1.encoding.to_s : $KCODE).downcase.start_with?('u')
      end

      def split_as_bigrams(str)
        str.split.map { |word| "##{word}#" }
                 .map { |word| (0..word.length-2).map { |i| word[i,2] } }
                 .flatten
      end
    end
  end
end
