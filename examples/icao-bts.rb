#!/usr/bin/env ruby
unless RUBY_VERSION >= '1.9'
  require 'rubygems'
end
require 'remote_table'
require 'ruby-debug'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'loose_tight_dictionary'

$log = $stderr

@haystack = RemoteTable.new :url => 'http://www.bts.gov/programs/airline_information/accounting_and_reporting_directives/csv/number_260.csv',
                        :select => lambda { |record| record['Aircraft Type'].to_i.between?(1, 998) and record['Manufacturer'].present? }

@tightenings = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=0&output=csv', :headers => false

@identities = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=3&output=csv', :headers => false

@blockings = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=4&output=csv', :headers => false

@positives = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=1&output=csv', :headers => false

@negatives = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=2&output=csv', :headers => false

# %w{ tightenings identities blockings positives negatives}.each do |name|
#   $stderr.puts name
#   $stderr.puts "\n" + instance_variable_get("@#{name}").to_a.map { |x| x.inspect }.join("\n")
#   $stderr.puts "\n"
# end

# @needles = ('A'..'Z').map do |letter|
# @needles = %w{ A B D G }.map do |letter|
@needles = %w{ B }.map do |letter|
  t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-#{letter}.htm",
    :encoding => 'US-ASCII',
    :row_xpath => '//table/tr[2]/td/table/tr',
    :column_xpath => 'td'
  t.to_a
end.flatten

d = LooseTightDictionary.new @haystack,
  :tightenings => @tightenings.map { |row| row.values[0] },
  :identities => @identities.map { |row| row.values[0] },
  :blockings => @blockings.map { |row| row.values[0] },
  :log => $log,
  :needle_reader => lambda { |record| (record['Manufacturer'] + ' ' + record['Model']).downcase },
  :haystack_reader => lambda { |record| (record['Manufacturer'] + ' ' + record['Long Name']).downcase },
  :positives => @positives,
  :negatives => @negatives,
  :strict_blocking => true

# d.improver.explain('boeing 767300')
d.improver.check @needles

# 0.62
# boeing 767300
# boeing boeing 737-300
