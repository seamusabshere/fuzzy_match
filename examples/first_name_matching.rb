#!/usr/bin/env ruby
unless RUBY_VERSION >= '1.9'
  require 'rubygems'
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'loose_tight_dictionary'

right_side = [ 'seamus', 'andy', 'ben' ]
left_side = [ 'Mr. Seamus', 'Sr. Andy', 'Master BenT', 'Shamus Heaney' ]

puts "Left side (input)"
puts "=" * 20
puts left_side
puts

puts "Right side (output)"
puts "=" * 20
puts right_side
puts

puts "Results"
puts "=" * 20
d = LooseTightDictionary.new right_side, :tee => $stdout
d.improver.check left_side
