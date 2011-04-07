class LooseTightDictionary
  # "Record linkage typically involves two main steps: blocking and scoring..."
  # http://en.wikipedia.org/wiki/Record_linkage
  #
  # Blockings effectively divide up the haystack into groups that match a pattern
  #
  # A blocking (as in a grouping) comes into effect when a str matches
  # Then the needle must also match the blocking's regexp
  class Blocking
    include ExtractRegexp
    
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = extract_regexp regexp_or_str
    end

    def encompass?(str1, str2 = nil)
      str1 = str1.ltd_to_str if str1.respond_to?(:ltd_to_str)
      str2 = str2.ltd_to_str if str2.respond_to?(:ltd_to_str)
      if str2.nil?
        !!(regexp.match(str1))
      elsif str2_match_data = regexp.match(str2)
        if str1_match_data = regexp.match(str1)
          str2_match_data.captures == str1_match_data.captures
        else
          false
        end
      else
        nil
      end
    end
  end
end
