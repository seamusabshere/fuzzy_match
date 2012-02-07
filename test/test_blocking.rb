require 'helper'

class TestBlocking < MiniTest::Spec
  it %{matches a single string argument} do
    b = FuzzyMatch::Blocking.new %r{apple}
    b.match?('2 apples').must_equal true
  end

  it %{embraces case insensitivity} do
    b = FuzzyMatch::Blocking.new %r{apple}i
    b.match?('2 Apples').must_equal true
  end
  
  it %{joins two string arguments} do
    b = FuzzyMatch::Blocking.new %r{apple}
    b.join?('apple', '2 apples').must_equal true
  end
  
  it %{fails to join two string arguments} do
    b = FuzzyMatch::Blocking.new %r{apple}
    b.join?('orange', '2 apples').must_equal false
  end
  
  it %{returns nil instead of false when it has no information} do
    b = FuzzyMatch::Blocking.new %r{apple}
    b.join?('orange', 'orange').must_be_nil
  end
end
