class LooseTightDictionary
  class Similarity
    attr_reader :wrapper1
    attr_reader :wrapper2
    
    def initialize(wrapper1, wrapper2)
      @wrapper1 = wrapper1
      @wrapper2 = wrapper2
    end
    
    def <=>(other)
      by_score = best_score <=> other.best_score
      if by_score == 0
        original_weight <=> other.original_weight
      else
        by_score
      end
    end
    
    # Weight things towards short original strings
    def original_weight
      @original_weight ||= (1.0 / (wrapper1.render.length * wrapper2.render.length))
    end
    
    def best_score
      @best_score ||= Score.new best_wrapper1_variant, best_wrapper2_variant
    end
    
    def best_wrapper1_variant
      best_variants[0]
    end
    
    def best_wrapper2_variant
      best_variants[1]
    end
    
    def best_variants
      @best_variants ||= wrapper1.variants.product(wrapper2.variants).sort do |tuple1, tuple2|
        wrapper1_variant1, wrapper2_variant1 = tuple1
        wrapper1_variant2, wrapper2_variant2 = tuple2

        score1 = Score.new wrapper1_variant1, wrapper2_variant1
        score2 = Score.new wrapper1_variant2, wrapper2_variant2
        
        score1 <=> score2
      end[-1]
    end
    
    def inspect
      %{#<Similarity "#{wrapper2.render}"=>"#{best_wrapper2_variant}" versus "#{wrapper1.render}"=>"#{best_wrapper1_variant}" original_weight=#{"%0.5f" % original_weight} best_score=#{best_score.inspect}>}
    end
  end
end
