require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "loose_tight_dictionary"
    gem.summary = %Q{Allows iterative development of dictionaries for big data sets.}
    gem.description = %Q{Create dictionaries that link rows between two tables (left and right) using loose matching (string similarity) by default and tight matching (regexp) by request.}
    gem.email = "seamus@abshere.net"
    gem.homepage = "http://github.com/seamusabshere/loose_tight_dictionary"
    gem.authors = ["Seamus Abshere"]
    gem.add_development_dependency "shoulda"
    gem.add_development_dependency "remote_table", ">=0.2.19"
    gem.add_dependency 'activesupport', '>=2.3.4'
    gem.add_dependency 'andand', '>=1.3.1'
    gem.add_dependency 'amatch', '>=0.2.5'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "loose_tight_dictionary #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
