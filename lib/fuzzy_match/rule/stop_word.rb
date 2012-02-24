class FuzzyMatch
  class Rule
    # A stop word is ignored
    class StopWord < Rule
      # Destructively remove stop words from the string
      def apply!(str)
        str.gsub! regexp, ''
      end
    end
  end
end
