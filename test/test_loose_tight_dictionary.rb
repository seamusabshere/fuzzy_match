require 'helper'

class TestLooseTightDictionary < Test::Unit::TestCase
  def setup
    @log = StringIO.new
  end
  
  def teardown
    @log.close
  end
  
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
  
  def test_004_false_positive_without_tightening
    d = LooseTightDictionary.new ['BOEING 737-100/200', 'BOEING 737-900']
    assert_equal 'BOEING 737-900', d.match('BOEING 737100')
  end
  
  def test_005_correct_with_tightening
    tightenings = [
      %r{(7\d)(7|0)-?(\d{1,3})}i # tighten 737-100/200 => 737100, which will cause it to win over 737-900
    ]
    d = LooseTightDictionary.new ['BOEING 737-100/200', 'BOEING 737-900'], :tightenings => tightenings, :log => @log
    d.improver.explain('BOEING 737100')
    @log.rewind
    output = @log.read
    assert_match %r{"boeing 737100" => "737100"}, output
  end

  def test_006_false_positive_without_blocking
    d = LooseTightDictionary.new [ 'A1', 'A2', 'B 1' ]
    assert_equal 'B 1', d.match('A 1')
  end
  
  def test_007_block_false_positive
    blockings = [
      %r{A}i # block things with A to only match things that also contain A
    ]
    d = LooseTightDictionary.new [ 'A1', 'A2', 'B 1' ], :blockings => blockings
    assert_equal 'A1', d.match('A 1')
  end
  
  def test_008_false_positive_without_identity
    d = LooseTightDictionary.new [ 'A2', 'B1', 'B2' ]
    assert_equal 'A2', d.match('A 1')
  end
  
  def test_008_identify_false_positive
    identities = [
      %r{(A)[ ]*(\d+)}i # if both sides match A*\d+, make sure they match exactly
    ]
    d = LooseTightDictionary.new [ 'A2', 'B1', 'B2' ], :identities => identities, :log => @log
    assert(d.match('A 1') != 'A2')
  end
end
