class LooseTightDictionary
  class Result #:nodoc: all
    attr_accessor :needle
    attr_accessor :tightenings
    attr_accessor :blockings
    attr_accessor :identities
    attr_accessor :encompassed
    attr_accessor :unencompassed
    attr_accessor :possibly_identical
    attr_accessor :certainly_different
    attr_accessor :scores
    attr_accessor :record
    attr_accessor :score
    
    def haystack
      encompassed + unencompassed
    end
    
    def free
      # nothing to see here
    end
  end
end
