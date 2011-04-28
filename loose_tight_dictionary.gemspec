# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "loose_tight_dictionary/version"

Gem::Specification.new do |s|
  s.name        = "loose_tight_dictionary"
  s.version     = LooseTightDictionary::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/loose_tight_dictionary"
  s.summary     = %Q{Allows iterative development of dictionaries for big data sets.}
  s.description = %Q{Create dictionaries that link rows between two tables using loose matching (string similarity) by default and tight matching (regexp) by request.}

  s.rubyforge_project = "loose_tight_dictionary"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,floose_tight_dictionaryures}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "shoulda"
  s.add_development_dependency "remote_table"
  s.add_dependency 'activesupport', '>=2.3.4'
  s.add_dependency 'amatch'
  s.add_dependency 'to_regexp', '>=0.0.3'
end
