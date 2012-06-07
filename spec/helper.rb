require 'bundler/setup'

require 'carbon'

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
