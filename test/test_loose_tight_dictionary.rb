require 'helper'

class TestLooseTightDictionary < Test::Unit::TestCase
  def test_001_match
    d = LooseTightDictionary.new %w{ nissan honda }
    assert_equal 'nissan', d.match('MISSAM')
  end
  
  def test_002_match_with_score
    d = LooseTightDictionary.new %w{ nissan honda }
    assert_equal ['nissan', 0.6], d.match_with_score('MISSAM')
  end
  
  def test_003_last_result
    d = LooseTightDictionary.new %w{ nissan honda }
    d.match 'MISSAM'
    assert_equal 0.6, d.last_result.score
    assert_equal 'nissan', d.last_result.match
  end
end
