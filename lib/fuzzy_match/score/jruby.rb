class FuzzyMatch
  class Score
    # be sure to run this with JRuby
    class JRuby < Score

      def dices_coefficient_similar
        @dices_coefficient_similar ||= if str1 == str2
          1.0
        elsif str1.length == 1 and str2.length == 1
          0.0
        else
          java_import "info.debatty.java.stringsimilarity.SorensenDice"
          Java::InfoDebattyJavaStringsimilarity::SorensenDice.new(2).similarity(str1, str2)
        end
      end

      def levenshtein_similar
        @levenshtein_similar ||= levenshtein
      end

      def levenshtein
        java_import "info.debatty.java.stringsimilarity.Levenshtein"
        1 - Java::InfoDebattyJavaStringsimilarity::Levenshtein.new.distance(str1, str2)
      end
    end
  end
end
