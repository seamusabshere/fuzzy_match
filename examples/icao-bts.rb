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

# $ltd_left = /(super|bonanza)/i
# $ltd_right = /bonanza d-35/i
# $ltd_dd_left = /bonanza/i
# $ltd_dd_right = /musk/i
# $ltd_dd_left_not = /allison/i
# $ltd_dd_print = true
# $ltd_ddd_left = /bonanza/i
# $ltd_ddd_right = /musk/i
# $ltd_ddd_left_not = /allison/i
# $ltd_ddd_print = true

@right = RemoteTable.new :url => 'http://www.bts.gov/programs/airline_information/accounting_and_reporting_directives/csv/number_260.csv',
                        :select => lambda { |record| record['Aircraft Type'].to_i.between?(1, 998) and record['Manufacturer'].present? }

@tightenings = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=0&output=csv', :headers => false

@restrictions = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=3&output=csv', :headers => false

@blockings = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=4&output=csv', :headers => false

@positives = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=1&output=csv', :headers => false

@negatives = RemoteTable.new :url => 'http://spreadsheets.google.com/pub?key=tiS_6CCDDM_drNphpYwE_iw&single=true&gid=2&output=csv', :headers => false

%w{ tightenings restrictions blockings }.each do |name|
  $logger.info name
  $logger.info "\n" + instance_variable_get("@#{name}").to_a.map { |record| record[0] }.join("\n")
  $logger.info "\n"
end

('A'..'Z').each do |letter|
# %w{ E }.each do |letter|
  @left = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-#{letter}.htm",
                          :encoding => 'US-ASCII',
                          :row_xpath => '//table/tr[2]/td/table/tr',
                          :column_xpath => 'td'

  d = LooseTightDictionary.new @right, :tightenings => @tightenings, :restrictions => @restrictions, :blockings => @blockings, :logger => $logger, :tee => $tee
  d.left_reader = lambda { |record| record['Manufacturer'] + ' ' + record['Model'] }
  d.right_reader = lambda { |record| record['Manufacturer'] + ' ' + record['Long Name'] }
  d.positives = @positives
  d.negatives = @negatives
  d.check @left
end
