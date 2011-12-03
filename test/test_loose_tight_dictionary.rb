require 'helper'

class TestLooseTightDictionary < Test::Unit::TestCase
  # in case i start doing something with the log
  # def setup
  #   @log = StringIO.new
  # end
  # 
  # def teardown
  #   @log.close
  # end
  
  def test_001_find
    d = LooseTightDictionary.new %w{ NISSAN HONDA }
    assert_equal 'NISSAN', d.find('MISSAM')
  end
  
  def test_002_dont_gather_last_result_by_default
    d = LooseTightDictionary.new %w{ NISSAN HONDA }
    d.find('MISSAM')
    assert_raises(::RuntimeError, /gather_last_result/) do
      d.last_result
    end
  end
  
  def test_003_last_result
    d = LooseTightDictionary.new %w{ NISSAN HONDA }
    d.find 'MISSAM', :gather_last_result => true
    assert_equal 0.6, d.last_result.score
    assert_equal 'NISSAN', d.last_result.record
  end
  
  def test_004_false_positive_without_tightener
    d = LooseTightDictionary.new ['BOEING 737-100/200', 'BOEING 737-900']
    assert_equal 'BOEING 737-900', d.find('BOEING 737100 number 900')
  end
  
  def test_005_correct_with_tightener
    tighteners = [
      %r{(7\d)(7|0)-?(\d{1,3})} # tighten 737-100/200 => 737100, which will cause it to win over 737-900
    ]
    d = LooseTightDictionary.new ['BOEING 737-100/200', 'BOEING 737-900'], :tighteners => tighteners
    assert_equal 'BOEING 737-100/200', d.find('BOEING 737100 number 900')
  end

  def test_008_false_positive_without_identity
    d = LooseTightDictionary.new %w{ foo bar }
    assert_equal 'bar', d.find('baz')
  end
  
  def test_008_identify_false_positive
    d = LooseTightDictionary.new %w{ foo bar }, :identities => [ /ba(.)/ ]
    assert_equal 'foo', d.find('baz')
  end
  
  def test_009_must_match_blocking
    d = LooseTightDictionary.new [ 'X' ]
    assert_equal 'X', d.find('X')
    assert_equal 'X', d.find('A')
    
    d = LooseTightDictionary.new [ 'X' ], :blockings => [ /X/, /Y/ ]
    assert_equal 'X', d.find('X')
    assert_equal 'X', d.find('A')
    
    d = LooseTightDictionary.new [ 'X' ], :blockings => [ /X/, /Y/ ], :must_match_blocking => true
    assert_equal 'X', d.find('X')
    assert_equal nil, d.find('A')
  end
    
  def test_011_free
    d = LooseTightDictionary.new %w{ NISSAN HONDA }
    d.free
    assert_raises(::RuntimeError, /free/) do
      d.find('foobar')
    end
  end
  
  def test_012_find_all
    d = LooseTightDictionary.new [ 'X', 'X22', 'Y', 'Y4' ], :blockings => [ /X/, /Y/ ], :must_match_blocking => true
    assert_equal ['X', 'X22' ], d.find_all('X')
    assert_equal [], d.find_all('A')
  end
  
  def test_013_first_blocking_decides
    d = LooseTightDictionary.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ]
    assert_equal [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], d.find_all('Boeing 747')
    
    d = LooseTightDictionary.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ], :first_blocking_decides => true
    assert_equal [ 'Boeing 747', 'Boeing 747SR' ], d.find_all('Boeing 747')
    
    # first_blocking_decides refers to the needle
    d = LooseTightDictionary.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ], :first_blocking_decides => true
    assert_equal [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], d.find_all('Boeing ER6')
    
    d = LooseTightDictionary.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing (7|E)/i, /boeing/i ], :first_blocking_decides => true
    assert_equal [ 'Boeing ER6' ], d.find_all('Boeing ER6')

    # or equivalently with an identity
    d = LooseTightDictionary.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ], :first_blocking_decides => true, :identities => [ /boeing (7|E)/i ]
    assert_equal [ 'Boeing ER6' ], d.find_all('Boeing ER6')
  end
end
