require 'helper'

class TestWrapper < Test::Unit::TestCase
  def test_001_apostrophe_s_is_not_a_word
    assert_split ["foo's", "bar"], "Foo's Bar"
  end
  
  def test_002_bolivia_comma_is_just_bolivia
    assert_split ["bolivia", "plurinational", "state"], "Bolivia, Plurinational State"
  end
  
  def test_003_hyphenated_words_are_not_split_up
    assert_split ['north-west'], "north-west"
  end
  
  def test_004_as_expected
    assert_split ['the', 'quick', "fox's", 'mouth', 'is', 'always', 'full'], "the quick fox's mouth -- is always full."
  end
  
  private
  
  def assert_split(ary, str)
    assert_equal ary, FuzzyMatch::Wrapper.new(null_fuzzy_match, str, true).words
  end
  
  def null_fuzzy_match
    FuzzyMatch.new []
  end
end
