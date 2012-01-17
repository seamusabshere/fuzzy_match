# -*- encoding: utf-8 -*-
require 'helper'

class TestFuzzyMatch < Test::Unit::TestCase
  def test_001_find
    d = FuzzyMatch.new %w{ RATZ CATZ }
    assert_equal 'RATZ', d.find('RITZ')
    assert_equal 'RATZ', d.find('RíTZ')
    
    d = FuzzyMatch.new [ 'X' ]
    assert_equal 'X', d.find('X')
    assert_equal nil, d.find('A')
  end
  
  def test_002_dont_gather_last_result_by_default
    d = FuzzyMatch.new %w{ NISSAN HONDA }
    d.find('MISSAM')
    assert_raises(::RuntimeError, /gather_last_result/) do
      d.last_result
    end
  end
  
  def test_003_last_result
    d = FuzzyMatch.new %w{ NISSAN HONDA }
    d.find 'MISSAM', :gather_last_result => true
    assert_equal 0.6, d.last_result.score
    assert_equal 'NISSAN', d.last_result.winner
  end
  
  def test_004_false_positive_without_tightener
    d = FuzzyMatch.new ['BOEING 737-100/200', 'BOEING 737-900']
    assert_equal 'BOEING 737-900', d.find('BOEING 737100 number 900')
  end
  
  def test_005_correct_with_tightener
    tighteners = [
      %r{(7\d)(7|0)-?(\d{1,3})} # tighten 737-100/200 => 737100, which will cause it to win over 737-900
    ]
    d = FuzzyMatch.new ['BOEING 737-100/200', 'BOEING 737-900'], :tighteners => tighteners
    assert_equal 'BOEING 737-100/200', d.find('BOEING 737100 number 900')
  end
  
  def test_008_false_positive_without_identity
    d = FuzzyMatch.new %w{ foo bar }
    assert_equal 'bar', d.find('baz')
  end
  
  def test_008_identify_false_positive
    d = FuzzyMatch.new %w{ foo bar }, :identities => [ /ba(.)/ ]
    assert_equal nil, d.find('baz')
  end
  
  # TODO this is not very helpful
  def test_009_blocking
    d = FuzzyMatch.new [ 'X' ], :blockings => [ /X/, /Y/ ]
    assert_equal 'X', d.find('X')
    assert_equal nil, d.find('A')
  end
  
  # TODO this is not very helpful
  def test_0095_must_match_blocking
    d = FuzzyMatch.new [ 'X' ], :blockings => [ /X/, /Y/ ], :must_match_blocking => true
    assert_equal 'X', d.find('X')
    assert_equal nil, d.find('A')
    
    d = FuzzyMatch.new [ 'X' ], :blockings => [ /X/, /Y/ ]
    assert_equal 'X', d.find('X', :must_match_blocking => true)
    assert_equal nil, d.find('A', :must_match_blocking => true)
  end
    
  def test_011_free
    d = FuzzyMatch.new %w{ NISSAN HONDA }
    d.free
    assert_raises(::RuntimeError, /free/) do
      d.find('foobar')
    end
  end
  
  def test_012_find_all
    d = FuzzyMatch.new [ 'X', 'X22', 'Y', 'Y4' ], :blockings => [ /X/, /Y/ ], :must_match_blocking => true
    assert_equal ['X', 'X22' ], d.find_all('X')
    assert_equal [], d.find_all('A')
  end
  
  def test_013_first_blocking_decides
    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ]
    assert_equal [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], d.find_all('Boeing 747')
    
    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ], :first_blocking_decides => true
    assert_equal [ 'Boeing 747', 'Boeing 747SR' ], d.find_all('Boeing 747')
    
    # first_blocking_decides refers to the needle
    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ], :first_blocking_decides => true
    assert_equal ["Boeing ER6", "Boeing 747", "Boeing 747SR"], d.find_all('Boeing ER6')
    
    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing (7|E)/i, /boeing/i ], :first_blocking_decides => true
    assert_equal [ 'Boeing ER6' ], d.find_all('Boeing ER6')
  
    # or equivalently with an identity
    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ], :first_blocking_decides => true, :identities => [ /boeing (7|E)/i ]
    assert_equal [ 'Boeing ER6' ], d.find_all('Boeing ER6')
  end
  
  MyStruct = Struct.new(:one, :two)
  def test_014_symbol_read_sends_method
    ab = MyStruct.new('a', 'b')
    ba = MyStruct.new('b', 'a')
    haystack = [ab, ba]
    by_first = FuzzyMatch.new haystack, :read => :one
    by_last = FuzzyMatch.new haystack, :read => :two
    assert_equal :one, by_first.read
    assert_equal :two, by_last.read
    assert_equal ab, by_first.find('a')
    assert_equal ab, by_last.find('b')
    assert_equal ba, by_first.find('b')
    assert_equal ba, by_last.find('a')
  end
  
  def test_015_symbol_read_reads_array
    ab = ['a', 'b']
    ba = ['b', 'a']
    haystack = [ab, ba]
    by_first = FuzzyMatch.new haystack, :read => 0
    by_last = FuzzyMatch.new haystack, :read => 1
    assert_equal ab, by_first.find('a')
    assert_equal ab, by_last.find('b')
    assert_equal ba, by_first.find('b')
    assert_equal ba, by_last.find('a')
  end
  
  def test_016_symbol_read_reads_hash
    ab = { :one => 'a', :two => 'b' }
    ba = { :one => 'b', :two => 'a' }
    haystack = [ab, ba]
    by_first = FuzzyMatch.new haystack, :read => :one
    by_last = FuzzyMatch.new haystack, :read => :two
    assert_equal ab, by_first.find('a')
    assert_equal ab, by_last.find('b')
    assert_equal ba, by_first.find('b')
    assert_equal ba, by_last.find('a')
  end
  
  def test_017_understands_haystack_reader_option
    ab = ['a', 'b']
    ba = ['b', 'a']
    haystack = [ab, ba]
    by_first = FuzzyMatch.new haystack, :haystack_reader => 0
    assert_equal ab, by_first.find('a')
    assert_equal ba, by_first.find('b')
  end
  
  def test_018_no_result_if_best_score_is_zero
    assert_equal nil, FuzzyMatch.new(['a']).find('b')
  end
  
  def test_019_must_match_at_least_one_word
    d = FuzzyMatch.new %w{ RATZ CATZ }, :must_match_at_least_one_word => true
    assert_equal nil, d.find('RITZ')
    
    d = FuzzyMatch.new ["Foo's Bar"], :must_match_at_least_one_word => true
    assert_equal nil, d.find("Jacob's")
    assert_equal "Foo's Bar", d.find("Foo's")
  end
  
  def test_020_stop_words
    d = FuzzyMatch.new [ 'A HOTEL', 'B HTL' ]
    assert_equal 'B HTL', d.find('A HTL', :must_match_at_least_one_word => true)
    
    d = FuzzyMatch.new [ 'A HOTEL', 'B HTL' ], :must_match_at_least_one_word => true
    assert_equal 'B HTL', d.find('A HTL')
    
    d = FuzzyMatch.new [ 'A HOTEL', 'B HTL' ], :must_match_at_least_one_word => true, :stop_words => [ %r{HO?TE?L} ]
    assert_equal 'A HOTEL', d.find('A HTL')
  end
  
  def test_021_explain_prints_to_stdout
    require 'stringio'
    capture = StringIO.new
    begin
      old_stdout = $stdout
      $stdout = capture
      d = FuzzyMatch.new %w{ RATZ CATZ }
      d.explain('RITZ')
    ensure
      $stdout = old_stdout
    end
    capture.rewind
    assert capture.read.include?('CATZ')
  end
  
  def test_022_compare_words_with_words
    d = FuzzyMatch.new [ 'PENINSULA HOTELS' ], :must_match_at_least_one_word => true
    assert_equal nil, d.find('DOLCE LA HULPE BXL FI')
  end
  
  def test_023_must_match_at_least_one_word_is_case_insensitive
    d = FuzzyMatch.new [ 'A', 'B' ]
    assert_equal 'A', d.find('a', :must_match_at_least_one_word => true)
  end
  
end
