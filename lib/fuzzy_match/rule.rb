class FuzzyMatch
  # A rule characterized by a regexp. Abstract.
  class Rule
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = regexp_or_str.to_regexp
    end
    
    def ==(other)
      regexp == other.regexp
    end
  end
end
