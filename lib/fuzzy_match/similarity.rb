class FuzzyMatch
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
    
    def best_score
      @best_score ||= FuzzyMatch.score_class.new(best_wrapper1_variant, best_wrapper2_variant)
    end

    def satisfy?(needle, threshold)
      best_score.dices_coefficient_similar > threshold or
        ((wrapper2.render.length < 3 or needle.render.length < 3) and best_score.levenshtein_similar > 0) or
        (needle.words & wrapper2.words).any?
    end

    def inspect
      %{#<FuzzyMatch::Similarity #{wrapper2.render.inspect}=>#{best_wrapper2_variant.inspect} versus #{wrapper1.render.inspect}=>#{best_wrapper1_variant.inspect} original_weight=#{"%0.5f" % original_weight} best_score=#{best_score.inspect}>}
    end

    # Weight things towards short original strings
    def original_weight
      @original_weight ||= (1.0 / (wrapper1.render.length * wrapper2.render.length))
    end

    private
        
    def best_wrapper1_variant
      best_variants[0]
    end
    
    def best_wrapper2_variant
      best_variants[1]
    end
    
    def best_variants
      @best_variants ||= begin
        wrapper1.variants.product(wrapper2.variants).sort do |tuple1, tuple2|
          wrapper1_variant1, wrapper2_variant1 = tuple1
          wrapper1_variant2, wrapper2_variant2 = tuple2
          score1 = FuzzyMatch.score_class.new wrapper1_variant1, wrapper2_variant1
          score2 = FuzzyMatch.score_class.new wrapper1_variant2, wrapper2_variant2
          score1 <=> score2
        end.last
      end
    end
  end
end
