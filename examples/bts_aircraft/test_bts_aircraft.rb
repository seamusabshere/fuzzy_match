require File.expand_path('../../../test/helper.rb', __FILE__)

require 'shoulda'

# How to iteratively develop a dictionary.

####################################################
# Section 1 - constants that will get passed as arguments

# The records that your dictionary will return.
# (Example) A table of aircraft as defined by the U.S. Bureau of Transportation Statistics
HAYSTACK = RemoteTable.new :url => "file://#{File.expand_path('../number_260.csv', __FILE__)}", :select => lambda { |record| record['Aircraft Type'].to_i.between?(1, 998) and record['Manufacturer'].present? }

# A reader used to convert every record (which could be an object of any type) into a string that will be used for comparison.
# (Example) Combine the make and model into something like "boeing 747"
# Note the downcase!
HAYSTACK_READER = lambda { |record| "#{record['Manufacturer']} #{record['Long Name']}".downcase }

# Whether to even bother trying to find a match for something without an explicit block
# (Example) False, which is the default, which means we have more work to do
STRICT_BLOCKING = false

# Blockings
# (Example) We made these by trial and error
BLOCKINGS = RemoteTable.new(:url => "file://#{File.expand_path("../blockings.csv", __FILE__)}", :headers => :first_row).map { |row| row['regexp'] }

# Tightenings
# (Example) We made these by trial and error
TIGHTENINGS = RemoteTable.new(:url => "file://#{File.expand_path("../tightenings.csv", __FILE__)}", :headers => :first_row).map { |row| row['regexp'] }

# Identities
# (Example) We made these by trial and error
IDENTITIES = RemoteTable.new(:url => "file://#{File.expand_path("../identities.csv", __FILE__)}", :headers => :first_row).map { |row| row['regexp'] }

####################################################
# Section 2 - constants that are just for tests

# The class of each record.
# (Example) ActiveSupport::OrderedHash because we're using RemoteTable
HAYSTACK_RECORD_CLASS = HAYSTACK[0].class

# Some test needles to be found in the haystack.
# (Example) Aircraft starting with A, B, D, G from the FAA (really a list of ICAO aircraft)
NEEDLES = %w{ A B D G }.inject([]) do |memo, letter|
  one_letter = RemoteTable.new :url => "file://#{File.expand_path("../5-2-#{letter}.htm", __FILE__)}",
    :encoding => 'US-ASCII',
    :row_xpath => '//table/tr[2]/td/table/tr',
    :column_xpath => 'td'
  memo + one_letter.to_a
end

# Positive matches that we know about.
# (Example) We just built this file in Excel and exported it to a CSV.
POSITIVES = RemoteTable.new :url => "file://#{File.expand_path("../positives.csv", __FILE__)}", :headers => :first_row

# Negative (false positive) matches that we know about.
# (Example) We just built this file in Excel and exported it to a CSV.
NEGATIVES = RemoteTable.new :url => "file://#{File.expand_path("../negatives.csv", __FILE__)}", :headers => :first_row

####################################################
# Section 3

FINAL_OPTIONS = {
  :haystack_reader => HAYSTACK_READER,
  :strict_blocking => STRICT_BLOCKING,
  :tightenings => TIGHTENINGS,
  :identities => IDENTITIES,
  :blockings => BLOCKINGS
}

class TestBtsAircraft < Test::Unit::TestCase
  should "store the records somewhere" do
    d = LooseTightDictionary.new HAYSTACK
    assert d.records.grep(/BOEING 707-100/)
  end
  
  should "understand records by using the haystack reader" do
    d = LooseTightDictionary.new HAYSTACK, FINAL_OPTIONS
    assert d.haystack.map { |record| record.to_str }.include?('boeing boeing 707-100')
  end

  should "find an easy match" do
    d = LooseTightDictionary.new HAYSTACK, FINAL_OPTIONS
    record = d.find('Boeing Sparticus 707(100)')
    assert_equal HAYSTACK_RECORD_CLASS, record.class
    assert_equal HAYSTACK_READER.call(record), 'boeing boeing 707-100'
  end
  
  POSITIVES.each do |row|
    needle = row['needle']
    correct_record = row['haystack']
    should %{find #{correct_record.blank? ? 'nothing' : correct_record} when looking for #{needle}} do
      d = LooseTightDictionary.new HAYSTACK, FINAL_OPTIONS
      record = d.find(needle.downcase)
      assert_equal correct_record.downcase, HAYSTACK_READER.call(record)
    end
  end
  
  NEGATIVES.each do |row|
    needle = row['needle']
    incorrect_record = row['haystack']
    should %{not find #{incorrect_record} when looking for #{needle}} do
      d = LooseTightDictionary.new HAYSTACK, FINAL_OPTIONS
      record = d.find(needle.downcase)
      assert(incorrect_record.downcase != HAYSTACK_READER.call(record))
    end
  end
end

# why?
#     1) Failure:
# test: BtsAircraft should find AIRBUS INDUSTRIE AIRBUS INDUSTRIE A340-300 when looking for AIRBUS A340300. (TestBtsAircraft)
#     [examples/bts_aircraft/test_bts_aircraft.rb:96:in `__bind_1302579566_46630'
#      /Users/seamus/.rvm/gems/ruby-1.8.7-p334/gems/shoulda-2.11.3/lib/shoulda/context.rb:382:in `call'
#      /Users/seamus/.rvm/gems/ruby-1.8.7-p334/gems/shoulda-2.11.3/lib/shoulda/context.rb:382:in `test: BtsAircraft should find AIRBUS INDUSTRIE AIRBUS INDUSTRIE A340-300 when looking for AIRBUS A340300. ']:
# <"airbus industrie airbus industrie a340-300"> expected but was
# <"airbus industrie airbus industrie a340">.

# d = LooseTightDictionary.new HAYSTACK, FINAL_OPTIONS
# puts d.improver.explain('ANTONOV An12'.downcase)

# 
# 
# @tightenings = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=0&output=csv', :headers => false
# 
# @identities = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=3&output=csv', :headers => false
# 
# @blockings = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=4&output=csv', :headers => false
# 
# @positives = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=1&output=csv', :headers => false
# 
# @negatives = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=2&output=csv', :headers => false
# 
# # %w{ tightenings identities blockings positives negatives}.each do |name|
# #   $stderr.puts name
# #   $stderr.puts "\n" + instance_variable_get("@#{name}").to_a.map { |x| x.inspect }.join("\n")
# #   $stderr.puts "\n"
# # end
# 
# # @needles = ('A'..'Z').map do |letter|
# # @needles = %w{ A B D G }.map do |letter|
# @needles = %w{ B }.map do |letter|
#   t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-#{letter}.htm",
#     :encoding => 'US-ASCII',
#     :row_xpath => '//table/tr[2]/td/table/tr',
#     :column_xpath => 'td'
#   t.to_a
# end.flatten
# 
# d = LooseTightDictionary.new @haystack,
#   :tightenings => @tightenings.map { |row| row.values[0] },
#   :identities => @identities.map { |row| row.values[0] },
#   :blockings => @blockings.map { |row| row.values[0] },
#   :log => $log,
#   :needle_reader => lambda { |record| (record['Manufacturer'] + ' ' + record['Model']).downcase }, # disable this if you're doine the explain line
#   :haystack_reader => 
#   :positives => @positives,
#   :negatives => @negatives,
#   :strict_blocking => true
# 
# # d.improver.explain('boeing 767300')
# d.improver.check @needles
# 
# # 0.62
# # boeing 767300
# # boeing boeing 737-300
