class FuzzyMatch
  # Wrappers are the tokens that are passed around when doing scoring and optimizing.
  class Wrapper #:nodoc: all
    # "Foo's" is one word
    # "North-west" is just one word
    # "Bolivia," is just Bolivia
    WORD_BOUNDARY = %r{\W*(?:\s+|$)}

    attr_reader :fuzzy_match
    attr_reader :record
    attr_reader :literal
    attr_reader :rendered

    def initialize(fuzzy_match, record, literal = false)
      @fuzzy_match = fuzzy_match
      @record = record
      @literal = literal
      @render_mutex = ::Mutex.new
      @words_mutex = ::Mutex.new
      @variants_mutex = ::Mutex.new
    end

    def inspect
      "#<FuzzyMatch::Wrapper render=#{render.inspect} variants=#{variants.length}>"
    end
    
    def read
      fuzzy_match.read unless literal
    end

    def render
      return @render if @rendered == true
      @render_mutex.synchronize do
        return @render if @rendered == true
        memo = case read
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
          stop_word.apply! memo
        end
        memo.strip!
        @render = memo.freeze
        @rendered = true
      end
      @render
    end

    alias :to_str :render

    def words
      @words || @words_mutex.synchronize do
        @words ||= render.downcase.split(WORD_BOUNDARY)
      end
    end

    def similarity(other)
      Similarity.new self, other
    end

    def variants
      @variants || @variants_mutex.synchronize do
        @variants ||= begin
          fuzzy_match.normalizers.inject([ render ]) do |memo, normalizer|
            if normalizer.apply? render
              memo << normalizer.apply(render)
            end
            memo
          end.uniq
        end
      end
    end
  end
end
