class FuzzyMatch
  # Wrappers are the tokens that are passed around when doing scoring and optimizing.
  class Wrapper #:nodoc: all
    attr_reader :fuzzy_match
    attr_reader :record
    attr_reader :literal
    attr_reader :rendered

    def initialize(fuzzy_match, record, literal = false)
      @fuzzy_match = fuzzy_match
      @record = record
      @literal = literal
    end

    def inspect
      "#<Wrapper render=#{render} variants=#{variants.length}>"
    end
    
    def read
      fuzzy_match.read unless literal
    end

    def render
      return @render if rendered
      str = case read
      when ::Proc
        read.call record
      when ::Symbol
        if record.respond_to?(read)
          record.send read
        else
          record[read]
        end
      when ::NilClass
        record
      else
        record[read]
      end.to_s.dup
      fuzzy_match.stop_words.each do |stop_word|
        stop_word.apply! str
      end
      str.strip!
      @render = str.freeze
      @rendered = true
      @render
    end

    alias :to_str :render

    # "Foo's" is one word
    # "North-west" is just one word
    # "Bolivia," is just Bolivia
    WORD_BOUNDARY = %r{\W*(?:\s+|$)}
    def words
      @words ||= render.downcase.split(WORD_BOUNDARY)
    end

    def similarity(other)
      Similarity.new self, other
    end

    def variants
      @variants ||= fuzzy_match.normalizers.inject([ render ]) do |memo, normalizer|
        if normalizer.apply? render
          memo.push normalizer.apply(render)
        end
        memo
      end.uniq
    end
  end
end
