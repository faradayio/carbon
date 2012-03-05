Gem::Specification.new do |s|
  s.name        = 'brighter_planet_api'
  s.version     = '0.0.1'
  s.author      = 'Seamus Abshere'
  s.email       = 'seamus@abshere.net'
  s.summary     = 'Brighter Planet API client for Ruby'
  s.description = 'Brighter Planet API client for Ruby'

  s.files         = ['brighter_planet_api.rb']
  s.require_path  = '.'
  s.add_runtime_dependency 'httpclient'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'concur'
  s.add_runtime_dependency 'multi_json'
  s.add_runtime_dependency 'hashie'
  # s.add_runtime_dependency 'brighter_planet_metadata'
end
