#!/usr/bin/env ruby

require 'rubygems'
require 'remote_table'
require 'ruby-debug'
require 'logger'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'loose_tight_dictionary.rb'))

$logger = Logger.new STDERR
$logger.level = Logger::DEBUG
$logger.datetime_format = "%H:%M:%S"
# $tee = File.open('tee.csv', 'w')
$tee = STDOUT

# icao_d = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-D.htm",
#                        :encoding => 'US-ASCII',
#                        :row_xpath => '//table/tr[2]/td/table/tr',
#                        :column_xpath => 'td'
icao_b = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-B.htm",
                      :encoding => 'US-ASCII',
                      :row_xpath => '//table/tr[2]/td/table/tr',
                      :column_xpath => 'td',
                      :select => lambda { |row| row['Manufacturer'].to_s =~ /boeing/i }

bts = RemoteTable.new :url => 'http://www.bts.gov/programs/airline_information/accounting_and_reporting_directives/csv/number_260.csv',
                      :select => lambda { |row| row['Aircraft Type'].to_i.between?(1, 998) and row['Manufacturer'].present? }

tightenings = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=0&output=csv', :headers => false

restrictions = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=3&output=csv', :headers => false

positives = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=1&output=csv', :headers => false

negatives = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=2&output=csv', :headers => false

# d = LooseTightDictionary.new icao_d, bts, tightenings, restrictions, :logger => $logger
# d.left_reader = lambda { |row| row['Manufacturer'] + ' ' + row['Model'] }
# d.right_reader = lambda { |row| row['Manufacturer'] + ' ' + row['Long Name'] }
# d.check positives, negatives

b = LooseTightDictionary.new icao_b, bts, tightenings, restrictions, :logger => $logger, :tee => $tee
b.left_reader = lambda { |row| row['Manufacturer'] + ' ' + row['Model'] }
b.right_reader = lambda { |row| row['Manufacturer'] + ' ' + row['Long Name'] }
b.check positives, negatives
