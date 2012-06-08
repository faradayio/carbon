require 'bundler/setup'

if ::Bundler.definition.specs['debugger'].first
  require 'debugger'
end

require 'carbon'

$:.unshift File.expand_path('../support', __FILE__)

module Utilities
  def flush_cache!
    CacheMethod.config.storage.flush
  end
end

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :fakeweb
end

RSpec.configure do |c|
  c.include Utilities
end
