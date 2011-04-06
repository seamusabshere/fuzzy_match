class LooseTightDictionary
  # "Record linkage typically involves two main steps: blocking and scoring..."
  # http://en.wikipedia.org/wiki/Record_linkage
  #
  # Blockings effectively divide up the haystack into groups that match a pattern
  #
  # A blocking (as in a grouping) comes into effect when a record matches
  # Then the needle must also match the blocking's regexp
  class Blocking
    include ExtractRegexp
    
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = extract_regexp regexp_or_str
    end

    def encompass?(value1, value2 = nil)
      if value2.nil?
        !!(regexp.match(value1))
      elsif value2_match_data = regexp.match(value2)
        if value1_match_data = regexp.match(value1)
          value2_match_data.captures == value1_match_data.captures
        else
          false
        end
      else
        nil
      end
    end
  end
end
