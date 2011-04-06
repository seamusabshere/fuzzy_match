require 'helper'

class TestIdentity < Test::Unit::TestCase
  def test_001_allow
    i = LooseTightDictionary::Identity.new %r{(A)[ ]*(\d)}
    assert i.allow?('A1', 'A     1foobar')
  end
  
  def test_002_disallow
    i = LooseTightDictionary::Identity.new %r{(A)[ ]*(\d)}
    assert !i.allow?('A1', 'A     2foobar')    
  end
end
