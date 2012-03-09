# -*- encoding: utf-8 -*-
require File.expand_path('../lib/carbon/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'carbon'
  s.version     = Carbon::VERSION
  s.author      = 'Seamus Abshere'
  s.email       = ['seamus@abshere.net', 'dkastner@gmail.com', 'andy@rossmeissl.net']
  s.summary     = 'Brighter Planet API client for Ruby'
  s.description = 'Brighter Planet API client for Ruby'
  s.homepage    = 'https://github.com/brighterplanet/carbon'

  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'em-http-request'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'multi_json'
  s.add_runtime_dependency 'hashie'

  # CLI
  s.add_runtime_dependency 'bombshell'
  s.add_runtime_dependency 'conversions'
  s.add_runtime_dependency 'brighter_planet_metadata'
end
