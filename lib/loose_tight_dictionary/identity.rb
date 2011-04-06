class LooseTightDictionary
  # Identities take effect when needle and haystack both match a regexp
  # Then the captured part of the regexp has to match exactly
  class Identity
    include ExtractRegexp
    
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = extract_regexp regexp_or_str
    end
    
    def possibly_identical?(needle_value, value)
      if needle_match_data = regexp.match(needle_value) and match_data = regexp.match(value)
        needle_match_data.captures == match_data.captures
      else
        true
      end
    end
  end
end
