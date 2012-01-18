require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'yard'
require File.expand_path('../lib/fuzzy_match/version.rb', __FILE__)
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'README.markdown']   # optional
  # t.options = ['--any', '--extra', '--opts'] # optional
end
