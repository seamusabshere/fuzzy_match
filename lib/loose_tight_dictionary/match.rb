class LooseTightDictionary
  class Match
    attr_accessor :unblocked
    attr_accessor :blocked
    attr_accessor :sorted
    attr_accessor :match
    
    def records
      @records ||= {}
    end
    
    def register_record(record, t_needle, t_haystack, prefix, score)
      records[record] = Record.new(t_needle, t_haystack, prefix, score)
    end
    
    def score
      records[match].score
    end
    
    def free
      records.clear
    end
        
    class Record
      attr_reader :t_needle
      attr_reader :t_haystack
      attr_reader :prefix
      attr_reader :score
      
      def initialize(t_needle, t_haystack, prefix, score)
        @t_needle = t_needle
        @t_haystack = t_haystack
        @prefix = prefix
        @score = score
      end
      
      def inspect
        [ t_needle.tightened_str, t_haystack.tightened_str, prefix, score ].map { |i| i.to_s.ljust(30) }.join 
      end
      alias :to_s :inspect
    end
  end
end
