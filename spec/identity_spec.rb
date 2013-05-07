require 'spec_helper'

describe FuzzyMatch::Rule::Identity do
  it %{determines whether two records COULD be identical} do
    i = FuzzyMatch::Rule::Identity.new %r{(A)[ ]*(\d)}
    i.identical?('A1', 'A     1foobar').should == true
  end
  
  it %{determines that two records MUST NOT be identical} do
    i = FuzzyMatch::Rule::Identity.new %r{(A)[ ]*(\d)}
    i.identical?('A1', 'A     2foobar').should == false
  end
  
  it %{returns nil indicating no information} do
    i = FuzzyMatch::Rule::Identity.new %r{(A)[ ]*(\d)}
    i.identical?('B1', 'A     2foobar').should == nil
  end

  it %{can be initialized with a regexp} do
    i = FuzzyMatch::Rule::Identity.new %r{\A\\?/(.*)etc/mysql\$$}
    i.regexp.should == %r{\A\\?/(.*)etc/mysql\$$}
  end
  
  it %{does not automatically convert strings to regexps} do
    lambda do
      FuzzyMatch::Rule::Identity.new '%r{\A\\\?/(.*)etc/mysql\$$}'
    end.should raise_error(ArgumentError, /regexp/i)
  end
  
  it %{embraces case insensitivity} do
    i = FuzzyMatch::Rule::Identity.new %r{(A)[ ]*(\d)}i
    i.identical?('A1', 'a     1foobar').should == true
  end
end
