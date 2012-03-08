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
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'brighter_planet_api'

BrighterPlanetApi.config[:key] = 'brighter_planet_api_test'

class MyNissanAltima
  class << self
    def all(options)
      raise unless options == { :order => :year }
      [ new(2000), new(2001), new(2002), new(2003), new(2004) ]
    end
  end
  def initialize(model_year)
    @model_year = model_year
  end
  def       make; 'Nissan'    end
  def      model; 'Altima'    end
  def model_year; @model_year end # what BP knows as "year"
  def  fuel_type; 'R'         end # what BP knows as "automobile_fuel" and keys on "code"
  include BrighterPlanetApi
  emit_as 'Automobile' do
    provide :make
    provide :model
    provide :model_year, :as => :year
    provide :fuel_type, :as => :automobile_fuel, :key => :code
  end
end

describe BrighterPlanetApi do
  # args could be mmm(:post, 'http://impact.brighterplanet.com/monkeys.json').to_return(:status => 500, :body => 'too many monkeys')
  describe :query do
    it "calculates flight impact" do
      response = BrighterPlanetApi.query('Flight', :origin_airport => 'LAX', :destination_airport => 'SFO', :segments_per_trip => 1, :trips => 1)
      response.decisions.carbon.object.value.must_be_close_to 200, 50
    end
    it "gets back characteristics" do
      response = BrighterPlanetApi.query('Flight', :origin_airport => 'LAX', :destination_airport => 'SFO', :segments_per_trip => 1, :trips => 1)
      response.characteristics.origin_airport.description.must_match %r{lax}i
    end
    it "tells you if the query is successful" do
      response = BrighterPlanetApi.query('Flight')
      response.success.must_equal true
    end
    it "is gentle about errors" do
      response = BrighterPlanetApi.query('Monkey')
      response.success.must_equal false
    end
    it "sends timeframe properly" do
      response = BrighterPlanetApi.query('Flight', :timeframe => Timeframe.new(:year => 2009))
      response.timeframe.startDate.must_equal '2009-01-01'
      response.timeframe.endDate.must_equal '2010-01-01'
    end
    it "sends key properly" do
      with_web_mock do
        WebMock.stub_request(:post, 'http://impact.brighterplanet.com/flights.json').with(:key => 'brighter_planet_api_test').to_return(:status => 500, :body => 'Good job')
        response = BrighterPlanetApi.query('Flight')
        response.errors.first.must_equal 'Good job'
      end
    end
  end
  unless ENV['SKIP_MULTI'] == 'true'
    describe :multi do
      before do
        @queries = []
        10.times do
          @queries << ['Flight', {:origin_airport => 'LAX', :destination_airport => 'SFO', :segments_per_trip => 1, :trips => 1}]
          @queries << ['RailTrip', {:distance => 25}]
          @queries << ['AutomobileTrip', {:make => 'Nissan', :model => 'Altima'}]
          @queries << ['Residence']
          @queries << ['Monkey']
        end
        @queries = @queries.sort_by { rand }
      end
      it "runs multiple queries at once" do
        responses = BrighterPlanetApi.multi(@queries)
        error_count = 0
        responses.each do |response|
          if response.success
            response.decisions.carbon.object.value.must_be :>, 0
            response.decisions.carbon.object.value.must_be :<, 10_000
          else
            error_count += 1
          end
        end
        error_count.must_equal 10
        @queries.each_with_index do |query, i|
          reference_response = BrighterPlanetApi.query(*query)
          if reference_response.success
            responses[i].decisions.must_equal reference_response.decisions
          end
        end
      end
      it "is faster than just calling #query over and over" do
        # dry run
        @queries.each { |query| BrighterPlanetApi.query(*query) }
        # --
        single_threaded_time = ::Benchmark.realtime do
          @queries.each { |query| BrighterPlanetApi.query(*query) }
        end
        multi_threaded_time = ::Benchmark.realtime do
          BrighterPlanetApi.multi(@queries)
        end
        # BrighterPlanet::Api::#multi
        #    PASS test_0001_runs_multiple_queries_at_once (12.10s)
        #    Multi-threaded was 95% faster - aw yah
        #    PASS test_0002_is_faster_than_just_calling_query_over_and_over (23.73s)
        $stderr.puts "   Multi-threaded was #{((single_threaded_time - multi_threaded_time) / single_threaded_time * 100).round}% faster"
        multi_threaded_time.must_be :<, single_threaded_time
      end
    end
  end
  describe '#impact' do
    it "works" do
      impact = MyNissanAltima.new(2006).impact
      impact.decisions.carbon.object.value.must_be :>, 0
      impact.characteristics.make.description.must_match %r{Nissan}i
      impact.characteristics.model.description.must_match %r{Altima}i
      impact.characteristics.year.description.to_i.must_equal 2006
      impact.characteristics.automobile_fuel.description.must_match %r{regular gasoline}
    end
  end
  describe :impacts do
    it "works" do
      impacts = BrighterPlanetApi.impacts(MyNissanAltima.all(:order => :year))
      impacts.length.must_equal 5
      impacts.map do |impact|
        impact.decisions.carbon.object.value.round
      end.uniq.length.must_be :>, 3
      impacts.each_with_index do |impact, idx|
        impact.decisions.carbon.object.value.must_be :>, 0
        impact.characteristics.make.description.must_match %r{Nissan}i
        impact.characteristics.year.description.to_i.must_equal(2000+idx)
      end
    end
  end
end
