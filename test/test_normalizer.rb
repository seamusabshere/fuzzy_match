require 'helper'

class TestNormalizer < Test::Unit::TestCase
  def test_001_apply
    t = FuzzyMatch::Normalizer.new %r{(Ford )[ ]*(F)[\- ]*(\d\d\d)}i
    assert_equal 'Ford F350', t.apply('Ford F-350')
    assert_equal 'Ford F150', t.apply('Ford F150')
    assert_equal 'Ford F350', t.apply('Ford F 350')
  end
end
