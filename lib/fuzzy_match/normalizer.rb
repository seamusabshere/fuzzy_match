class FuzzyMatch
  # A normalizer just strips a string down to its core
  class Normalizer
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = regexp_or_str.to_regexp
    end
    
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
    
    def inspect
      "#<FuzzyMatch::Normalizer regexp=#{regexp.inspect}>"
    end
  end
end
