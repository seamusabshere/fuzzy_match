class FuzzyMatch
  class Rule
    # Identities take effect when needle and haystack both match a regexp
    # Then the captured part of the regexp has to match exactly
    class Identity < Rule
      # Two strings are "identical" if they both match this identity and the captures are equal.
      #
      # Only returns true/false if both strings match the regexp.
      # Otherwise returns nil.
      def identical?(record1, record2)
        if str1_match_data = regexp.match(record1.whole) and str2_match_data = regexp.match(record2.whole)
          str1_match_data.captures.join.downcase == str2_match_data.captures.join.downcase
        else
          nil
        end
      end
    end
  end
end
