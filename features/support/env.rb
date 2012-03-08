require 'aruba/cucumber'
require 'fileutils'

$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'carbon/shell'

Before do
  @aruba_io_wait_seconds = 2
  @aruba_timeout_seconds = 5
  @dirs = [File.join(ENV['HOME'], 'carbon_features')]
end
