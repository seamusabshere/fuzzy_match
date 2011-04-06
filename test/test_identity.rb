require 'helper'

class TestIdentity < Test::Unit::TestCase
  def test_001_possibly_identical
    i = LooseTightDictionary::Identity.new %r{(A)[ ]*(\d)}
    assert i.possibly_identical?('A1', 'A     1foobar')
  end
  
  def test_002_certainly_different
    i = LooseTightDictionary::Identity.new %r{(A)[ ]*(\d)}
    assert !i.possibly_identical?('A1', 'A     2foobar')    
  end
end
