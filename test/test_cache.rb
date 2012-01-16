require 'helper'

require 'active_support/all'
require 'active_record'
require 'cohort_scope'
require 'weighted_average'

ActiveRecord::Base.establish_connection(
  'adapter' => 'mysql',
  'database' => 'fuzzy_match_test',
  'username' => 'root',
  'password' => 'password'
)

# ActiveRecord::Base.logger = Logger.new $stderr

ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable 'aircraft'
end

require 'fuzzy_match/cached_result'

::FuzzyMatch::CachedResult.setup(true)
::FuzzyMatch::CachedResult.delete_all

class Aircraft < ActiveRecord::Base
  set_primary_key :icao_code
  
  cache_fuzzy_match_with :flight_segments, :primary_key => :aircraft_description, :foreign_key => :aircraft_description
    
  def aircraft_description
    [manufacturer_name, model_name].compact.join(' ')
  end
  
  def self.fuzzy_match
    @fuzzy_match ||= FuzzyMatch.new all, :read => ::Proc.new { |straw| straw.aircraft_description }
  end
  
  def self.create_table
    connection.drop_table(:aircraft) rescue nil
    connection.execute %{
CREATE TABLE `aircraft` (
  `icao_code` varchar(255) DEFAULT NULL,
  `manufacturer_name` varchar(255) DEFAULT NULL,
  `model_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`icao_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    }
    reset_column_information
  end
end

class FlightSegment < ActiveRecord::Base
  set_primary_key :row_hash
  
  cache_fuzzy_match_with :aircraft, :primary_key => :aircraft_description, :foreign_key => :aircraft_description
  
  extend CohortScope
  self.minimum_cohort_size = 1
  
  def self.create_table
    connection.drop_table(:flight_segments) rescue nil
    connection.execute %{
CREATE TABLE `flight_segments` (
  `row_hash` varchar(255) NOT NULL DEFAULT '',
  `aircraft_description` varchar(255) DEFAULT NULL,
  `passengers` int(11) DEFAULT NULL,
  `seats` int(11) DEFAULT NULL,
  PRIMARY KEY (`row_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    }
  end
end

FlightSegment.create_table
Aircraft.create_table

a = Aircraft.new
a.icao_code = 'B742'
a.manufacturer_name = 'Boeing'
a.model_name = '747-200'
a.save!

fs = FlightSegment.new
fs.row_hash = 'madison to chicago'
fs.aircraft_description = 'BORING 747200'
fs.passengers = 10
fs.seats = 10
fs.save!

fs = FlightSegment.new
fs.row_hash = 'madison to minneapolis'
fs.aircraft_description = 'bing 747'
fs.passengers = 100
fs.seats = 5
fs.save!

FlightSegment.find_each do |fs|
  fs.cache_aircraft!
end

class TestCache < Test::Unit::TestCase
  def test_002_one_degree_of_separation
    aircraft = Aircraft.find('B742')
    assert_equal 2, aircraft.flight_segments.count
  end
  
  def test_003_standard_sql_calculations
    aircraft = Aircraft.find('B742')
    assert_equal 110, aircraft.flight_segments.sum(:passengers)
  end
  
  def test_004_weighted_average
    aircraft = Aircraft.find('B742')
    assert_equal 5.45455, aircraft.flight_segments.weighted_average(:seats, :weighted_by => :passengers)
  end
  
  def test_005_right_way_to_do_cohorts
    aircraft = Aircraft.find('B742')
    assert_equal 2, FlightSegment.big_cohort(:aircraft_description => aircraft.flight_segments_foreign_keys).count
  end
  
  def test_006_you_can_get_aircraft_from_flight_segments
    fs = FlightSegment.first
    # you need to add an aircraft_description column
    assert_raises(ActiveRecord::StatementInvalid) do
      assert_equal 2, fs.aircraft.count
    end
  end
end
