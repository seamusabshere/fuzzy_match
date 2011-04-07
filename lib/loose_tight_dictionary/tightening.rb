class LooseTightDictionary
  # A tightening just strips a string down to its core
  class Tightening
    include ExtractRegexp
    
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = extract_regexp regexp_or_str
    end
    
    def apply?(str)
      str = str.ltd_to_str if str.respond_to?(:ltd_to_str)
      
      !!(regexp.match(str))
    end
    
    def apply(str)
      str = str.ltd_to_str if str.respond_to?(:ltd_to_str)
      
      if match_data = regexp.match(str)
        match_data.captures.join
      else
        str
      end
    end
  end
end
