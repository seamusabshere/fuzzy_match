class FuzzyMatch
  # Records are the tokens that are passed around when doing scoring and optimizing.
  class Record #:nodoc: all
    # "Foo's" is one word
    # "North-west" is just one word
    # "Bolivia," is just Bolivia
    WORD_BOUNDARY = %r{\W*(?:\s+|$)}
    EMPTY = [].freeze
    BLANK = ''.freeze

    attr_reader :original
    attr_reader :read
    attr_reader :stop_words

    def initialize(original, options = {})
      @original = original
      @read = options[:read]
      @stop_words = options.fetch(:stop_words, EMPTY)
    end

    def inspect
      "w(#{clean.inspect})"
    end

    def clean
      @clean ||= begin
        memo = whole.dup
        stop_words.each do |stop_word|
          memo.gsub! stop_word, BLANK
        end
        memo.strip.freeze
      end
    end

    def words
      @words ||= clean.downcase.split(WORD_BOUNDARY).freeze
    end

    def similarity(other)
      Similarity.new self, other
    end

    def interpret_record(read_field, record)
      case read_field
        when ::NilClass
          record
        when ::Numeric, ::String
          record[read_field]
        when ::Proc
          read_field.call record
        when ::Symbol
          record.respond_to?(read_field) ? record.send(read_field) : record[read_field]
        else
          raise "Expected nil, a proc, or a symbol, got #{read_field.inspect}"
        end
    end

    def whole
      @whole ||=
      if read.is_a? Enumerable
        # Read each field from the record specified
        totalrecord = ''
        read.each do |x|
          totalrecord += interpret_record(x, original).to_s.strip
        end
        totalrecord
      else
        interpret_record(read, original).to_s.strip
      end.freeze
    end
  end
end
