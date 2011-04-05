#!/usr/bin/env ruby
unless RUBY_VERSION >= '1.9'
  require 'rubygems'
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'loose_tight_dictionary'

haystack = [ 'seamus', 'andy', 'ben' ]
needles = [ 'Mr. Seamus', 'Sr. Andy', 'Master BenT', 'Shamus Heaney' ]

puts "Needles"
puts "=" * 20
puts needles
puts

puts "Haystack"
puts "=" * 20
puts haystack
puts

puts "Results"
puts "=" * 20
d = LooseTightDictionary.new haystack
d.improver.check needles
