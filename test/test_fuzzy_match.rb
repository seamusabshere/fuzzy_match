# -*- encoding: utf-8 -*-
require 'helper'

class TestFuzzyMatch < MiniTest::Spec
  it %{identify the best match based on string similarity} do
    d = FuzzyMatch.new %w{ RATZ CATZ }
    d.find('RITZ').must_equal 'RATZ'
    d.find('RíTZ').must_equal 'RATZ'

    d = FuzzyMatch.new [ 'X' ]
    d.find('X').must_equal 'X'
    d.find('A').must_be_nil
  end

  it %{not gather metadata about the last result by default} do
    d = FuzzyMatch.new %w{ NISSAN HONDA }
    d.find('MISSAM')
    lambda do
      d.last_result
    end.must_raise ::RuntimeError, /gather_last_result/
  end

  it %{optionally gather metadata about the last result} do
    d = FuzzyMatch.new %w{ NISSAN HONDA }
    d.find 'MISSAM', :gather_last_result => true
    d.last_result.score.must_equal 0.6
    d.last_result.winner.must_equal 'NISSAN'
  end

  it %{use NORMALIZERS} do
    d = FuzzyMatch.new ['BOEING 737-100/200', 'BOEING 737-900']
    d.find('BOEING 737100 number 900').must_equal 'BOEING 737-900'

    normalizers = [
      %r{(7\d)(7|0)-?(\d{1,3})} # tighten 737-100/200 => 737100, which will cause it to win over 737-900
    ]
    d = FuzzyMatch.new ['BOEING 737-100/200', 'BOEING 737-900'], :normalizers => normalizers
    d.find('BOEING 737100 number 900').must_equal 'BOEING 737-100/200'
  end

  it %{use IDENTITIES} do
    # false positive without identity
    d = FuzzyMatch.new %w{ foo bar }
    d.find('baz').must_equal 'bar'

    d = FuzzyMatch.new %w{ foo bar }, :identities => [ /ba(.)/ ]
    d.find('baz').must_be_nil
  end

  # TODO this is not very helpful
  it %{use BLOCKINGS} do
    d = FuzzyMatch.new [ 'X' ], :blockings => [ /X/, /Y/ ]
    d.find('X').must_equal 'X'
    d.find('A').must_be_nil
  end

  # TODO this is not very helpful
  it %{optionally only attempt matches with records that fit into a blocking} do
    d = FuzzyMatch.new [ 'X' ], :blockings => [ /X/, /Y/ ], :must_match_blocking => true
    d.find('X').must_equal 'X'
    d.find('A').must_be_nil

    d = FuzzyMatch.new [ 'X' ], :blockings => [ /X/, /Y/ ]
    d.find('X', :must_match_blocking => true).must_equal 'X'
    d.find('A', :must_match_blocking => true).must_be_nil
  end

  it %{receive the deprecated FuzzyMatch#free method without complaint} do
    d = FuzzyMatch.new %w{ A B }
    d.free
    d.find('A').wont_be_nil
  end

  it %{return all records in sorted order} do
    d = FuzzyMatch.new [ 'X', 'X22', 'Y', 'Y4' ], :blockings => [ /X/, /Y/ ], :must_match_blocking => true
    d.find_all('X').must_equal ['X', 'X22' ]
    d.find_all('A').must_equal []
  end

  it %{optionally force the first blocking to decide} do
    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ]
    d.find_all('Boeing 747').must_equal [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ]

    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ], :first_blocking_decides => true
    d.find_all('Boeing 747').must_equal [ 'Boeing 747', 'Boeing 747SR' ]

    # first_blocking_decides refers to the needle
    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ], :first_blocking_decides => true
    d.find_all('Boeing ER6').must_equal ["Boeing ER6", "Boeing 747", "Boeing 747SR"]

    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing (7|E)/i, /boeing/i ], :first_blocking_decides => true
    d.find_all('Boeing ER6').must_equal [ 'Boeing ER6' ]

    # or equivalently with an identity
    d = FuzzyMatch.new [ 'Boeing 747', 'Boeing 747SR', 'Boeing ER6' ], :blockings => [ /(boeing \d{3})/i, /boeing/i ], :first_blocking_decides => true, :identities => [ /boeing (7|E)/i ]
    d.find_all('Boeing ER6').must_equal [ 'Boeing ER6' ]
  end

  describe "the :read option" do
    it %{interpret a Numeric as an array index} do
      ab = ['a', 'b']
      ba = ['b', 'a']
      haystack = [ab, ba]
      by_first = FuzzyMatch.new haystack, :read => 0
      by_last = FuzzyMatch.new haystack, :read => 1
      by_first.find('a').must_equal ab
      by_last.find('b').must_equal ab
      by_first.find('b').must_equal ba
      by_last.find('a').must_equal ba
    end

    it %{interpret a Symbol, etc. as hash key} do
      ab = { :one => 'a', :two => 'b' }
      ba = { :one => 'b', :two => 'a' }
      haystack = [ab, ba]
      by_first = FuzzyMatch.new haystack, :read => :one
      by_last = FuzzyMatch.new haystack, :read => :two
      by_first.find('a').must_equal ab
      by_last.find('b').must_equal ab
      by_first.find('b').must_equal ba
      by_last.find('a').must_equal ba
    end

    MyStruct = Struct.new(:one, :two)
    it %{interpret a Symbol as a method id (if the object responds to it)} do
      ab = MyStruct.new('a', 'b')
      ba = MyStruct.new('b', 'a')
      haystack = [ab, ba]
      by_first = FuzzyMatch.new haystack, :read => :one
      by_last = FuzzyMatch.new haystack, :read => :two
      by_first.read.must_equal :one
      by_last.read.must_equal :two
      by_first.find('a').must_equal ab
      by_last.find('b').must_equal ab
      by_first.find('b').must_equal ba
      by_last.find('a').must_equal ba
    end

    it %{treat the deprecrated :haystack_reader option as an alias} do
      ab = ['a', 'b']
      ba = ['b', 'a']
      haystack = [ab, ba]
      by_first = FuzzyMatch.new haystack, :haystack_reader => 0
      by_first.find('a').must_equal ab
      by_first.find('b').must_equal ba
    end
  end

  it %{not return any result if the maximum score is zero} do
    FuzzyMatch.new(['a']).find('b').must_be_nil
  end

  it %{optionally require that the matching record share at least one word with the needle} do
    d = FuzzyMatch.new %w{ RATZ CATZ }, :must_match_at_least_one_word => true
    d.find('RITZ').must_be_nil

    d = FuzzyMatch.new ["Foo's Bar"], :must_match_at_least_one_word => true
    d.find("Foo's").must_equal "Foo's Bar"
    d.find("'s").must_be_nil
    d.find("Foo").must_be_nil
    
    d = FuzzyMatch.new ["Bolivia, Plurinational State of"], :must_match_at_least_one_word => true
    d.find("Bolivia").must_equal "Bolivia, Plurinational State of"
  end

  it %{use STOP WORDS} do
    d = FuzzyMatch.new [ 'A HOTEL', 'B HTL' ]
    d.find('A HTL', :must_match_at_least_one_word => true).must_equal 'B HTL'

    d = FuzzyMatch.new [ 'A HOTEL', 'B HTL' ], :must_match_at_least_one_word => true
    d.find('A HTL').must_equal 'B HTL'

    d = FuzzyMatch.new [ 'A HOTEL', 'B HTL' ], :must_match_at_least_one_word => true, :stop_words => [ %r{HO?TE?L} ]
    d.find('A HTL').must_equal 'A HOTEL'
  end

  it %{print a basic explanation to stdout} do
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
    capture.read.must_include 'CATZ'
  end

  it %{not be fooled by substrings (but rather compare whole words to whole words)} do
    d = FuzzyMatch.new [ 'PENINSULA HOTELS' ], :must_match_at_least_one_word => true
    d.find('DOLCE LA HULPE BXL FI').must_be_nil
  end

  it %{not be case-sensitive when checking for sharing of words} do
    d = FuzzyMatch.new [ 'A', 'B' ]
    d.find('a', :must_match_at_least_one_word => true).must_equal 'A'
  end

end
