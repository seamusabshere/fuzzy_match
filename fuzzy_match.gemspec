# -*- encoding: utf-8 -*-
require File.expand_path("../lib/fuzzy_match/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fuzzy_match"
  s.version     = FuzzyMatch::VERSION
  s.authors     = ["Seamus Abshere"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/fuzzy_match"
  s.summary     = %Q{Find a needle in a haystack using string similarity and (optionally) regexp rules. Replaces loose_tight_dictionary.}
  s.description = %Q{Find a needle in a haystack using string similarity and (optionally) regexp rules. Replaces loose_tight_dictionary.}

  s.rubyforge_project = "fuzzy_match"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', '>=3'
  s.add_runtime_dependency 'to_regexp', '>=0.0.3'
  s.add_runtime_dependency 'active_record_inline_schema', '>=0.4.0'
end
