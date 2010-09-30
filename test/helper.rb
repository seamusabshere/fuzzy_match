require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'logger'
# require 'ruby-debug'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'loose_tight_dictionary'))

class Test::Unit::TestCase
end
