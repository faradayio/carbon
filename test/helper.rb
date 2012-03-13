require 'rubygems'
require 'bundler/setup'
require 'benchmark'
require 'webmock/minitest'
WebMock.disable!
def with_web_mock
  WebMock.enable!
  WebMock.disable_net_connect!
  yield
ensure
  WebMock.disable!
end
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new
require 'timeframe'
require 'carbon'

class MiniTest::Spec
  def flush_cache!
    CacheMethod.config.storage.flush
  end
end
