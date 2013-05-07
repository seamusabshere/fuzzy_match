class FuzzyMatch
  class Rule
    # "Record linkage typically involves two main steps: grouping and scoring..."
    # http://en.wikipedia.org/wiki/Record_linkage
    #
    # Groupings effectively divide up the haystack into groups that match a pattern
    #
    # A grouping (formerly known as a blocking) comes into effect when a str matches.
    # Then the needle must also match the grouping's regexp.
    class Grouping < Rule
      class << self
        def make(regexps)
          case regexps
          when ::Regexp
            new regexps
          when ::Array
            chain = regexps.flatten.map { |regexp| new regexp }
            chain.each { |grouping| grouping.chain = chain }
            chain
          else
            raise ArgumentError, "[fuzzy_match] Groupings should be specified as single regexps or an array of regexps (got #{regexps.inspect})"
          end
        end
      end

      attr_accessor :chain

      def target?(str)
        !!(regexp.match(str))
      end

      def xtarget?(str)
        if primary?
          target?(str) and subs.none? { |grouping| grouping.target?(str) }
        else
          target?(str) and primary.target?(str)
        end
      end

      def xjoin?(needle, straw)
        if primary?
          join?(needle, straw) and subs.none? { |grouping| grouping.xtarget?(straw) }
        else
          join?(needle, straw) and primary.target?(straw)
        end
      end

      protected

      def primary?
        chain ? (primary == self) : true
        # not chain or primary == self
      end

      def primary
        chain ? chain[0] : self
      end

      def subs
        chain ? chain[1..-1] : []
      end

      def join?(needle, straw)
        if straw_match_data = regexp.match(straw)
          if needle_match_data = regexp.match(needle)
            straw_match_data.captures.join.downcase == needle_match_data.captures.join.downcase
          else
            false
          end
        else
          nil
        end
      end
    end
  end
end
