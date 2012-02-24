class FuzzyMatch
  class Rule
    # A normalizer just strips a string down to its core
    class Normalizer < Rule
      # A normalizer applies when its regexp matches and captures a new (shorter) string
      def apply?(str)
        !!(regexp.match(str))
      end
    
      # The result of applying a normalizer is just all the captures put together.
      def apply(str)
        if match_data = regexp.match(str)
          match_data.captures.join
        else
          str
        end
      end
    end
  end
end
