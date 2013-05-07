require 'spec_helper'

describe FuzzyMatch::Rule::Normalizer do
  it %{applies itself to a string argument} do
    t = FuzzyMatch::Rule::Normalizer.new %r{(Ford )[ ]*(F)[\- ]*(\d\d\d)}i
    t.apply('Ford F-350').should == 'Ford F350'
    t.apply('Ford F150').should == 'Ford F150'
    t.apply('Ford F 350').should == 'Ford F350'
  end
end
