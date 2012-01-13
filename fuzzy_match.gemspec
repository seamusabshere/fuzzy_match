# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fuzzy_match/version"

Gem::Specification.new do |s|
  s.name        = "fuzzy_match"
  s.version     = FuzzyMatch::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/fuzzy_match"
  s.summary     = %Q{Allows iterative development of dictionaries for big data sets.}
  s.description = %Q{Create dictionaries that link rows between two tables using loose matching (string similarity) by default and tight matching (regexp) by request.}

  s.rubyforge_project = "fuzzy_match"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,ffuzzy_matchures}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "shoulda"
  s.add_development_dependency "remote_table"
  s.add_development_dependency 'activerecord', '>=3'
  s.add_development_dependency 'mysql'
  s.add_development_dependency 'cohort_scope'
  s.add_development_dependency 'weighted_average'
  s.add_development_dependency 'rake'
  # s.add_development_dependency 'amatch'
  s.add_runtime_dependency 'activesupport', '>=3'
  s.add_runtime_dependency 'to_regexp', '>=0.0.3'
end
