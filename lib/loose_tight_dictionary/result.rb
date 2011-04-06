class LooseTightDictionary
  class Result
    attr_reader :unblocked
    attr_reader :blocked
    attr_reader :match
    
    def tts
      @tts ||= []
    end
        
    def register_unblocked(unblocked)
      @unblocked = unblocked
    end
    
    def register_blocked(blocked)
      @blocked = blocked
    end
        
    def register_tt(t_needle, t_haystack, prefix, score)
      tts.push TT.new(t_needle, t_haystack, prefix, score)
    end
    
    def register_match(match)
      @match = match
    end
        
    def score
      tts.map { |tt| tt.score }.max
    end
    
    def free
      tts.try :clear
      @tts = nil
      @unblocked = nil
      @blocked = nil
      @match = nil
      @score = nil
    end
        
    class TT
      HEADERS = [ 'Score', 't_haystack [=> tightened/prefixed]', 't_needle [=> tightened/prefixed]' ]

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
        [
          score,
          (t_haystack.tightened? ? "#{t_haystack.str.inspect} => #{t_haystack.tightened_str.inspect}" : t_haystack.str.inspect),
          (t_needle.tightened? ? "#{t_needle.str.inspect} => #{t_needle.tightened_str.inspect}" : t_needle.str.inspect),
        ].map { |i| i.to_s.ljust(50) }.join.strip
      end
      
      alias :to_s :inspect
      
      def <=>(other)
        other.score <=> score
      end
      
      def eql?(other)
        hash == other.hash
      end
      
      def hash
        [ t_needle.tightened_str, t_haystack.tightened_str, score ].hash
      end
    end
  end
end
