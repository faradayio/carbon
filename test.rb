require 'rubygems'
require 'bundler/setup'
require 'benchmark'
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'brighter_planet_api'

BrighterPlanetApi.config[:key] = 'brighter_planet_api_test'

describe BrighterPlanetApi do
  describe '#query' do
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
  end
  describe '#multi' do
    before do
      @queries = []
      5.times do
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
      error_count.must_equal 5
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
      multi_threaded_time.must_be :<, single_threaded_time
    end
  end
  describe '#config' do
    it "lets you set an API key" do
      BrighterPlanetApi.config[:key].must_equal 'brighter_planet_api_test'
    end
  end
end
