class LooseTightDictionary
  # A tightener just strips a string down to its core
  class Tightener
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = regexp_or_str.is_a?(::Regexp) ? regexp_or_str : regexp_or_str.to_regexp
    end
    
    # A tightener applies when its regexp matches and captures a new (shorter) string
    def apply?(str)
      !!(regexp.match(str))
    end
    
    # The result of applying a tightener is just all the captures put together.
    def apply(str)
      if match_data = regexp.match(str)
        match_data.captures.join
      else
        str
      end
    end
    
    def inspect
      "#<Tightener regexp=#{regexp.inspect}>"
    end
  end
end
