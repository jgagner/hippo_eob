# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hippo_eob/version"

Gem::Specification.new do |s|
  s.name        = "hippo_eob"
  s.version     = HippoEob::VERSION
  s.authors     = ["Alopiano"]
  s.email       = ["alopiano@promedicalinc.com"]
  s.homepage    = ""
  s.summary     = %q{Generate a PDF EOB from a Hippo 835 Object (or by populating the objects themselves).}
  s.description = %q{Generate a PDF EOB from a Hippo 835 Object (or by populating the objects themselves).}

  s.rubyforge_project = "hippo_eob"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "hippo"
  s.add_runtime_dependency "prawn"
end
