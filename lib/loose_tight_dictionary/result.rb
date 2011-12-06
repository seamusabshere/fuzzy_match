class LooseTightDictionary
  class Result #:nodoc: all
    attr_accessor :needle
    attr_accessor :tighteners
    attr_accessor :blockings
    attr_accessor :identities
    attr_accessor :stop_words
    attr_accessor :candidates
    attr_accessor :joint
    attr_accessor :disjoint
    attr_accessor :possibly_identical
    attr_accessor :certainly_different
    attr_accessor :similarities
    attr_accessor :record
    attr_accessor :score
  end
end
