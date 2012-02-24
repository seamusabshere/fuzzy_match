require 'helper'

describe FuzzyMatch::Rule::Identity do
  it %{determines whether two records COULD be identical} do
    i = FuzzyMatch::Rule::Identity.new %r{(A)[ ]*(\d)}
    i.identical?('A1', 'A     1foobar').must_equal true
  end
  
  it %{determines that two records MUST NOT be identical} do
    i = FuzzyMatch::Rule::Identity.new %r{(A)[ ]*(\d)}
    i.identical?('A1', 'A     2foobar').must_equal false
  end
  
  it %{returns nil indicating no information} do
    i = FuzzyMatch::Rule::Identity.new %r{(A)[ ]*(\d)}
    i.identical?('B1', 'A     2foobar').must_equal nil
  end

  it %{can be initialized with a regexp} do
    i = FuzzyMatch::Rule::Identity.new %r{\A\\?/(.*)etc/mysql\$$}
    i.regexp.must_equal %r{\A\\?/(.*)etc/mysql\$$}
  end
  
  it %{can be initialized from a string (via to_regexp gem)} do
    i = FuzzyMatch::Rule::Identity.new '%r{\A\\\?/(.*)etc/mysql\$$}'
    i.regexp.must_equal %r{\A\\?/(.*)etc/mysql\$$}

    i = FuzzyMatch::Rule::Identity.new '/\A\\\?\/(.*)etc\/mysql\$$/'
    i.regexp.must_equal %r{\A\\?/(.*)etc/mysql\$$}
  end
  
  it %{embraces case insensitivity} do
    i = FuzzyMatch::Rule::Identity.new %r{(A)[ ]*(\d)}i
    i.identical?('A1', 'a     1foobar').must_equal true
  end
end
