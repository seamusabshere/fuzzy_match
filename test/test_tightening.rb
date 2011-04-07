require 'helper'

class TestTightening < Test::Unit::TestCase
  def test_001_apply
    t = LooseTightDictionary::Tightening.new %r{(Ford )[ ]*(F)[\- ]*(\d\d\d)}i
    assert_equal 'Ford F350', t.apply('Ford F-350')
    assert_equal 'Ford F150', t.apply('Ford F150')
    assert_equal 'Ford F350', t.apply('Ford F 350')
  end
end
