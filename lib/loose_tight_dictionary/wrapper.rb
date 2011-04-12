class LooseTightDictionary
  # Wrappers are the tokens that are passed around when doing scoring and optimizing.
  class Wrapper #:nodoc: all
    attr_reader :parent
    attr_reader :record
    attr_reader :reader

    def initialize(attrs = {})
      attrs.each do |k, v|
        instance_variable_set "@#{k}", v
      end
    end

    def inspect
      "#<Wrapper to_str=#{to_str} variants=#{variants.length}>"
    end

    def to_str
      @to_str ||= reader ? reader.call(record) : record.to_s
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
