class FuzzyMatch
  # "Record linkage typically involves two main steps: grouping and scoring..."
  # http://en.wikipedia.org/wiki/Record_linkage
  #
  # Groupings effectively divide up the haystack into groups that match a pattern
  #
  # A grouping (formerly known as a blocking) comes into effect when a str matches.
  # Then the needle must also match the grouping's regexp.
  class Grouping
    attr_reader :regexp
    
    def initialize(regexp_or_str)
      @regexp = regexp_or_str.to_regexp
    end

    def match?(str)
      !!(regexp.match(str))
    end
    
    def ==(other)
      regexp == other.regexp
    end

    # If a grouping "joins" two strings, that means they both fit into it.
    #
    # Returns false if they certainly don't fit this grouping.
    # Returns nil if the grouping doesn't apply, i.e. str2 doesn't fit the grouping.
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
