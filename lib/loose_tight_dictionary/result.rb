class LooseTightDictionary
  class Result
    attr_reader :unblocked
    attr_reader :blocked
    attr_reader :match
    
    def records
      @records ||= {}
    end
    
    def register_unblocked(unblocked)
      @unblocked = unblocked
    end
    
    def register_blocked(blocked)
      @blocked = blocked
    end
        
    def register_score(record, t_needle, t_haystack, prefix, score)
      records[record] = Record.new(t_needle, t_haystack, prefix, score)
    end
    
    def register_match(match)
      @match = match
    end
    
    def score
      records[match].score
    end
    
    def free
      records.try :clear
      @records = nil
      @unblocked = nil
      @blocked = nil
      @match = nil
    end
        
    class Record
      HEADERS = [ 'Needle', 'Haystack', 'Score', 'Prefix used (if any)']

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
        [ t_needle.tightened_str, t_haystack.tightened_str, score, prefix ].map { |i| i.to_s.ljust(30) }.join 
      end
      alias :to_s :inspect
    end
  end
end
