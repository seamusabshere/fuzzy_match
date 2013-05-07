# encoding: utf-8
require 'erb'
require 'yaml'

class FuzzyMatch
  class Result #:nodoc: all
    EXPLANATION = <<-ERB
#####################################################
# SUMMARY
#####################################################

<%= YAML.dump(needle: needle.render.inspect, match: winner.inspect) %>

#####################################################
# HAYSTACK
#####################################################

<%= YAML.dump(size: haystack.length, reader: read.inspect, examples: haystack[0, 3].map(&:render).map(&:inspect)) %>

#####################################################
# OPTIONS
#####################################################

<%= YAML.dump(options) %>

<% timeline.each_with_index do |event, index| %>
(<%= index+1 %>) <%= event %>
<% end %>
ERB

    attr_accessor :needle
    attr_accessor :read
    attr_accessor :haystack
    attr_accessor :options
    attr_accessor :normalizers
    attr_accessor :groupings
    attr_accessor :identities
    attr_accessor :stop_words
    attr_accessor :winner
    attr_accessor :score
    attr_reader :timeline

    def initialize
      @timeline = []
    end
    
    def explain
      $stdout.puts ::ERB.new(EXPLANATION, 0, '%<').result(binding)
    end
  end
end
