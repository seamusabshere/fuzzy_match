#!/usr/bin/env ruby
require 'rubygems'
# require 'loose_tight_dictionary'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'loose_tight_dictionary.rb'))
right_side = [ 'seamus', 'andy', 'ben' ]
left_side = [ 'Mr. Seamus', 'Sr. Andy', 'Master BenT' ]

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
d.check left_side

puts d.left_to_right 'Shamus Heaney'