unless RUBY_PLATFORM == 'java'
  require 'helper'
  require 'test_fuzzy_match'
  require 'amatch'
  
  class TestAmatch < TestFuzzyMatch
    before do
      $testing_amatch = true
      FuzzyMatch.engine = :amatch
    end
    after do
      $testing_amatch = false
      FuzzyMatch.engine = nil
    end
  end
end
