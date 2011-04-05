#!/usr/bin/env ruby
unless RUBY_VERSION >= '1.9'
  require 'rubygems'
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'loose_tight_dictionary'

haystack_side = [ 'seamus', 'andy', 'ben' ]
needle_side = [ 'Mr. Seamus', 'Sr. Andy', 'Master BenT', 'Shamus Heaney' ]

puts "Needle side (input)"
puts "=" * 20
puts needle_side
puts

puts "Haystack side (output)"
puts "=" * 20
puts haystack_side
puts

puts "Matchs"
puts "=" * 20
d = LooseTightDictionary.new haystack_side
d.improver.check needle_side
