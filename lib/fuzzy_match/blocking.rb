class FuzzyMatch
  # "Record linkage typically involves two main steps: blocking and scoring..."
  # http://en.wikipedia.org/wiki/Record_linkage
  #
  # Blockings effectively divide up the haystack into groups that match a pattern
  #
  # A blocking (as in a grouping) comes into effect when a str matches.
  # Then the needle must also match the blocking's regexp.
  class Blocking
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = regexp_or_str.to_regexp
    end

    def match?(str)
      !!(regexp.match(str))
    end

    # If a blocking "joins" two strings, that means they both fit into it.
    #
    # Returns false if they certainly don't fit this blocking.
    # Returns nil if the blocking doesn't apply, i.e. str2 doesn't fit the blocking.
    def join?(str1, str2)
      if str2_match_data = regexp.match(str2)
        if str1_match_data = regexp.match(str1)
          str2_match_data.captures.join.downcase == str1_match_data.captures.join.downcase
        else
          false
        end
      else
        nil
      end
    end
  end
end
