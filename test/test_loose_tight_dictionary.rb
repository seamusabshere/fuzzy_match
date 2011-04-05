require 'helper'
require 'stringio'

class TestLooseTightDictionary < Test::Unit::TestCase
  def setup
    @tee = StringIO.new
  end
  
  def teardown
    @tee.close
  end
  
  def test_001_find
    d = LooseTightDictionary.new %w{ nissan honda }, :tee => @tee
    assert_equal 'nissan', d.find('MISSAM')
  end
  
  def test_002_score
    d = LooseTightDictionary.new %w{ nissan honda }, :tee => @tee
    assert_equal ['nissan', 0.6], d.find_with_score('MISSAM')
  end
end
