require 'spec_helper'

describe FuzzyMatch::Rule::Grouping do
  it %{matches a single string argument} do
    b = FuzzyMatch::Rule::Grouping.new %r{apple}
    b.xtarget?('2 apples').should == true
  end

  it %{embraces case insensitivity} do
    b = FuzzyMatch::Rule::Grouping.new %r{apple}i
    b.xtarget?('2 Apples').should == true
  end
  
  it %{xjoins two string arguments} do
    b = FuzzyMatch::Rule::Grouping.new %r{apple}
    b.xjoin?('apple', '2 apples').should == true
  end
  
  it %{fails to xjoin two string arguments} do
    b = FuzzyMatch::Rule::Grouping.new %r{apple}
    b.xjoin?('orange', '2 apples').should == false
  end
  
  it %{returns nil instead of false when it has no information} do
    b = FuzzyMatch::Rule::Grouping.new %r{apple}
    b.xjoin?('orange', 'orange').should be_nil
  end

  it %{has chains} do
    h, gr, ga = FuzzyMatch::Rule::Grouping.make([/hyatt/, /grand/, /garden/])
    h.xjoin?('hyatt', 'hyatt').should == true

    h.xjoin?('grund hyatt', 'grand hyatt').should == true
    gr.xjoin?('grund hyatt', 'grand hyatt').should == false
    ga.xjoin?('grund hyatt', 'grand hyatt').should be_nil
    
    h.xjoin?('hyatt gurden', 'hyatt garden').should == true
    gr.xjoin?('hyatt gurden', 'hyatt garden').should be_nil
    ga.xjoin?('hyatt gurden', 'hyatt garden').should == false

    h.xjoin?('grand hyatt', 'grand hyatt').should == false # sacrificing itself
    gr.xjoin?('grand hyatt', 'grand hyatt').should == true
    ga.xjoin?('grand hyatt', 'grand hyatt').should be_nil

    h.xjoin?('hyatt garden', 'hyatt garden').should == false # sacrificing itself
    gr.xjoin?('hyatt garden', 'hyatt garden').should be_nil
    ga.xjoin?('hyatt garden', 'hyatt garden').should == true

    h.xjoin?('grand hyatt garden', 'grand hyatt garden').should == false # sacrificing itself
    gr.xjoin?('grand hyatt garden', 'grand hyatt garden').should == true
    ga.xjoin?('grand hyatt garden', 'grand hyatt garden').should == true # NOT sacrificing itself?
  end
end
