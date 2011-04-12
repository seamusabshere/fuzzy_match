require 'amatch'

class LooseTightDictionary
  class Similarity
    attr_reader :wrapper1
    attr_reader :wrapper2
    
    def initialize(wrapper1, wrapper2)
      @wrapper1 = wrapper1
      @wrapper2 = wrapper2
    end
    
    def <=>(other)
      if score != other.score
        score <=> other.score
      else
        length <=> other.length
      end
    end
    
    def score
      score_and_length[0]
    end
    
    def length
      score_and_length[1]
    end
        
    def score_and_length
      @score_and_length ||= Similarity.score_and_length(best_wrapper1_variant, best_wrapper2_variant)
    end
    
    def best_wrapper1_variant
      best_variants[0]
    end
    
    def best_wrapper2_variant
      best_variants[1]
    end
    
    def best_variants
      @best_variants ||= cart_prod(wrapper1.variants, wrapper2.variants).sort do |tuple1, tuple2|
        wrapper1_variant1, wrapper2_variant1 = tuple1
        wrapper1_variant2, wrapper2_variant2 = tuple2

        score1, length1 = Similarity.score_and_length(wrapper1_variant1, wrapper2_variant1)
        score2, length2 = Similarity.score_and_length(wrapper1_variant2, wrapper2_variant2)
        
        if score1 != score2
          score1 <=> score2
        else
          length1 <=> length2
        end
      end[-1]
    end

    class << self
      def score_and_length(wrapper1, wrapper2)
        length = [ wrapper1.to_str.length, wrapper2.to_str.length ].min
        score = wrapper1.to_str[0..length].pair_distance_similar(wrapper2.to_str[0..length])
        [ score, length ]
      end
    end
    
    def inspect
      %{#<Similarity score=#{score} length=#{length} wrapper1="#{wrapper1.to_str}" wrapper2="#{wrapper2.to_str}" best_wrapper1_variant="#{best_wrapper1_variant}" best_wrapper2_variant="#{best_wrapper2_variant}">}
    end
    
    # Thanks William James!
    # http://www.ruby-forum.com/topic/95519#200484
    def cart_prod(*args)
      args.inject([[]]){|old,lst|
        new = []
        lst.each{|e| new += old.map{|c| c.dup << e }}
        new
      }
    end
  end
end
