require 'rubygems'
require 'bundler/setup'

require 'minitest/spec'
require 'minitest/autorun'

if RUBY_VERSION >= '1.9'
  require 'minitest/reporters'
  MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new
end

require 'fuzzy_match'
