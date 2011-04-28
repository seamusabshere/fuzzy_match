require 'helper'

class TestBlocking < Test::Unit::TestCase
  def test_001_match_one
    b = LooseTightDictionary::Blocking.new %r{apple}
    assert_equal true, b.match?('2 apples')
  end
  
  def test_002_join_both
    b = LooseTightDictionary::Blocking.new %r{apple}
    assert_equal true, b.join?('apple', '2 apples')    
  end
  
  def test_002_doesnt_join_both
    b = LooseTightDictionary::Blocking.new %r{apple}
    assert_equal false, b.join?('orange', '2 apples')
  end
  
  def test_003_no_information
    b = LooseTightDictionary::Blocking.new %r{apple}
    assert_equal nil, b.join?('orange', 'orange')
  end
end
