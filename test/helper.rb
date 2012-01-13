require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'stringio'
require 'remote_table'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fuzzy_match'

class Test::Unit::TestCase
end
