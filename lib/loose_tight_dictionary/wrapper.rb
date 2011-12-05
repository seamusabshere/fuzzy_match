class LooseTightDictionary
  # Wrappers are the tokens that are passed around when doing scoring and optimizing.
  class Wrapper #:nodoc: all
    attr_reader :loose_tight_dictionary
    attr_reader :record
    attr_reader :read

    def initialize(loose_tight_dictionary, record, read = nil)
      @loose_tight_dictionary = loose_tight_dictionary
      @record = record
      @read = read
    end

    def inspect
      "#<Wrapper render=#{render} variants=#{variants.length}>"
    end

    def render
      return @render if rendered?
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
      loose_tight_dictionary.stop_words.each do |stop_word|
        stop_word.apply! str
      end
      @render = str.freeze
      @rendered = true
      @render
    end

    alias :to_str :render

    WORD_BOUNDARY = %r{\s*\b\s*}
    def words
      @words ||= render.split(WORD_BOUNDARY)
    end

    def similarity(other)
      Similarity.new self, other
    end

    def variants
      @variants ||= loose_tight_dictionary.tighteners.inject([ render ]) do |memo, tightener|
        if tightener.apply? render
          memo.push tightener.apply(render)
        end
        memo
      end.uniq
    end
    
    def rendered?
      @rendered == true
    end
  end
end
