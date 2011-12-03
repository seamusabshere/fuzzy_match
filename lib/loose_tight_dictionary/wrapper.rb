class LooseTightDictionary
  # Wrappers are the tokens that are passed around when doing scoring and optimizing.
  class Wrapper #:nodoc: all
    attr_reader :parent
    attr_reader :record
    attr_reader :read

    def initialize(parent, record, read = nil)
      @parent = parent
      @record = record
      @read = read
    end

    def inspect
      "#<Wrapper to_str=#{to_str} variants=#{variants.length}>"
    end

    def to_str
      @to_str ||= case read
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
      end.to_s
    end

    alias :to_s :to_str

    def similarity(other)
      Similarity.new self, other
    end

    def variants
      @variants ||= parent.tighteners.inject([ to_str ]) do |memo, tightener|
        if tightener.apply? to_str
          memo.push tightener.apply(to_str)
        end
        memo
      end.uniq
    end
  end
end
