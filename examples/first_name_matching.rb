#!/usr/bin/env ruby
unless RUBY_VERSION >= '1.9'
  require 'rubygems'
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'loose_tight_dictionary'

haystack = [ 'seamus', 'andy', 'ben' ]
needles = [ 'Mr. Seamus', 'Sr. Andy', 'Master BenT', 'Shamus Heaney' ]

d = LooseTightDictionary.new haystack
needles.each do |needle|
  d.explain needle
  puts
end
