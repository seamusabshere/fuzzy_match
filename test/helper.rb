require 'rubygems'
require 'bundler'
Bundler.setup
require 'minitest/spec'
require 'minitest/autorun'
require 'stringio'
require 'remote_table'
if ENV['AMATCH'] == 'true'
  require 'amatch'
end
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fuzzy_match'
