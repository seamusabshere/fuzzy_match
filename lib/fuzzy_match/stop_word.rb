class FuzzyMatch
  # A stop word is ignored
  class StopWord
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = regexp_or_str.to_regexp
    end
    
    # Destructively remove stop words from the string
    def apply!(str)
      str.gsub! regexp, ''
    end
    
    def inspect
      "#<FuzzyMatch::StopWord regexp=#{regexp.inspect}>"
    end
  end
end
