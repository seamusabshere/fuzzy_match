require 'helper'

class TestLooseTightDictionary < Test::Unit::TestCase
  def setup
    @log = StringIO.new
  end
  
  def teardown
    @log.close
  end
  
  def test_001_match
    d = LooseTightDictionary.new %w{ NISSAN HONDA }
    assert_equal 'NISSAN', d.match('MISSAM')
  end
  
  def test_002_match_with_score
    d = LooseTightDictionary.new %w{ NISSAN HONDA }
    assert_equal ['NISSAN', 0.6], d.match_with_score('MISSAM')
  end
  
  def test_003_last_result
    d = LooseTightDictionary.new %w{ NISSAN HONDA }
    d.match 'MISSAM'
    assert_equal 0.6, d.last_result.score
    assert_equal 'NISSAN', d.last_result.match
  end
  
  def test_004_false_positive_without_tightening
    d = LooseTightDictionary.new ['BOEING 737-100/200', 'BOEING 737-900']
    assert_equal 'BOEING 737-900', d.match('BOEING 737100')
  end
  
  def test_005_correct_with_tightening
    tightenings = [
      %r{(7\d)(7|0)-?(\d{1,3})} # tighten 737-100/200 => 737100, which will cause it to win over 737-900
    ]
    d = LooseTightDictionary.new ['BOEING 737-100/200', 'BOEING 737-900'], :tightenings => tightenings, :log => @log
    d.improver.explain('BOEING 737100')
    @log.rewind
    output = @log.read
    assert_match %r{"BOEING 737100" => "737100"}, output
  end

  def test_008_false_positive_without_identity
    d = LooseTightDictionary.new [ 'A2', 'B1', 'B2' ]
    assert_equal 'A2', d.match('A 1')
  end
  
  def test_008_identify_false_positive
    identities = [
      %r{(A)[ ]*(\d+)} # if both sides match A*\d+, make sure they match exactly
    ]
    d = LooseTightDictionary.new [ 'A2', 'B1', 'B2' ], :identities => identities
    assert(d.match('A 1') != 'A2')
  end
  
  def test_009_loose_blocking
    # sanity check
    d = LooseTightDictionary.new [ 'X' ]
    assert_equal 'X', d.match('X')
    assert_equal 'X', d.match('A')
    # end sanity check
    
    d = LooseTightDictionary.new [ 'X' ], :blockings => [ /X/, /Y/ ]
    assert_equal 'X', d.match('X')
    assert_equal 'X', d.match('A')
  end
  
  def test_010_strict_blocking
    d = LooseTightDictionary.new [ 'X' ], :blockings => [ /X/, /Y/ ], :strict_blocking => true
    assert_equal 'X', d.match('X')
    assert_equal nil, d.match('A')
  end
end
