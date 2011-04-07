require 'helper'

class TestIdentity < Test::Unit::TestCase
  def test_001_identical
    i = LooseTightDictionary::Identity.new %r{(A)[ ]*(\d)}
    assert_equal true, i.identical?('A1', 'A     1foobar')
  end
  
  def test_002_certainly_different
    i = LooseTightDictionary::Identity.new %r{(A)[ ]*(\d)}
    assert_equal false, i.identical?('A1', 'A     2foobar')    
  end
  
  def test_003_no_information_ie_possible_identical
    i = LooseTightDictionary::Identity.new %r{(A)[ ]*(\d)}
    assert_equal nil, i.identical?('B1', 'A     2foobar')    
  end
end
