Gem::Specification.new do |s|
  s.name        = 'carbon'
  s.version     = '0.0.1'
  s.author      = 'Seamus Abshere'
  s.email       = 'seamus@abshere.net'
  s.summary     = 'Brighter Planet API client for Ruby'
  s.description = 'Brighter Planet API client for Ruby'

  s.files         = ['carbon.rb']
  s.require_path  = '.'
  s.add_runtime_dependency 'em-http-request'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'multi_json'
  s.add_runtime_dependency 'hashie'
end