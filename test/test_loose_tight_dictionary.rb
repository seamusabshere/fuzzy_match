require 'helper'

$logger = Logger.new STDERR
$logger.level = Logger::INFO

class TestLooseTightDictionary < Test::Unit::TestCase
  def setup
    clear_ltd
    
    # dh 8 400
    @a_left, @a_right = 'DE HAVILLAND CANADA DHC8400 Dash 8', 'DEHAVILLAND DEHAVILLAND DHC8-400 DASH-8'
    # dh 88
    @b_left = 'ABCDEFG DH88 HIJKLMNOP'
    # dh 89
    @c_right = 'ABCDEFG DH89 HIJKLMNOP'
    # dh 8 200
    @d_left, @d_right = 'DE HAVILLAND CANADA DHC8200 Dash 8', 'BOMBARDIER DEHAVILLAND DHC8-200Q DASH-8'
    
    # good tightening for de havilland
    @t_1 = /(dh)c?-?(\d{0,2})-?(\d{0,4})(?:.*?)(dash|\z)/i
    
    # good restriction for de havilland
    @d_1 = /(dh)c?-?(\d{0,2})-?(\d{0,4})(?:.*?)(dash|\z)/i
    
    @left = [
      @a_left,
      @b_left,
      'DE HAVILLAND DH89 Dragon Rapide',
      'DE HAVILLAND CANADA DHC8100 Dash 8 (E9, CT142, CC142)',
      @d_left,
      'DE HAVILLAND CANADA DHC8300 Dash 8',
      'DE HAVILLAND DH90 Dragonfly'
    ]
    @right = [
      @a_right,
      @c_right,
      @d_right,
      'DEHAVILLAND DEHAVILLAND DHC8-100 DASH-8',
      'DEHAVILLAND DEHAVILLAND TWIN OTTER DHC-6'
    ]
    @tightenings = []
    @restrictions = []
    @positives = []
    @negatives = []
  end

  def clear_ltd
    @_ltd = nil
  end
  
  def ltd
    @_ltd ||= LooseTightDictionary.new @left, @right, @tightenings, @restrictions, :logger => $logger
  end

  should "perform lookups left to right" do
    assert_equal @a_right, ltd.left_to_right(@a_left)
  end
  
  should "perform lookups right to left" do
    assert_equal @a_left, ltd.right_to_left(@a_right)
  end

  should "succeed if there are no checks" do
    assert_nothing_raised do
      ltd.check @positives, @negatives
    end
  end
  
  should "succeed if the positive checks just work" do
    @positives.push [ @a_left, @a_right ]
    
    assert_nothing_raised do
      ltd.check @positives, @negatives
    end
  end
  
  should "fail if positive checks don't work" do
    @positives.push [ @d_left, @d_right ]
  
    assert_raises(LooseTightDictionary::Mismatch) do
      ltd.check @positives, @negatives
    end
  end
  
  should "succeed if proper tightening is applied" do
    @positives.push [ @d_left, @d_right ]
    @tightenings.push @t_1
  
    assert_nothing_raised do
      ltd.check @positives, @negatives
    end
  end
  
  should "fail if negative checks don't work" do
    @negatives.push [ @b_left, @c_right ]
    
    assert_raises(LooseTightDictionary::FalsePositive) do
      ltd.check @positives, @negatives
    end
  end
  
  should "fail if negative checks don't work, even with tightening" do
    @negatives.push [ @b_left, @c_right ]
    @tightenings.push @t_1
    
    assert_raises(LooseTightDictionary::FalsePositive) do
      ltd.check @positives, @negatives
    end
  end
  
  should "succeed if proper restriction is applied" do
    @negatives.push [ @b_left, @c_right ]
    @positives.push [ @d_left, @d_right ]
    @restrictions.push @d_1
    
    assert_nothing_raised do
      ltd.check @positives, @negatives
    end
  end
end
