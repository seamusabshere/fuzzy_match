require 'fuzzy_match/score/pure_ruby'
require 'fuzzy_match/score/amatch'

class FuzzyMatch
  class Score
    attr_reader :str1
    attr_reader :str2

    def initialize(str1, str2)
      @str1 = str1.downcase
      @str2 = str2.downcase
    end

    def <=>(other)
      by_dices_coefficient = (dices_coefficient_similar <=> other.dices_coefficient_similar)
      if by_dices_coefficient == 0
        levenshtein_similar <=> other.levenshtein_similar
      else
        by_dices_coefficient
      end
    end
  end
end
