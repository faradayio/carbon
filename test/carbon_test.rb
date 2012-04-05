require File.expand_path("../helper", __FILE__)

Thread.abort_on_exception = true
Carbon.key = 'carbon_test'

class MyNissan
  def name
    'Nissan'
  end
  def to_s
    raise "Not fair!"
  end
  alias :inspect :to_s
end

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
  def       make; MyNissan.new end
  def      model; 'Altima'     end
  def model_year; @model_year  end # what BP knows as "year"
  def  fuel_type; 'R'          end # what BP knows as "automobile_fuel" and keys on "code"
  def   nil_make; nil          end
  def  nil_model; nil          end
  include Carbon
  emit_as 'Automobile' do
    provide(:make) { |my_nissan_altima| my_nissan_altima.make.try(:name) }
    provide :model
    provide :model_year, :as => :year
    provide :fuel_type, :as => :automobile_fuel, :key => :code
    provide(:nil_make) { |my_nissan_altima| my_nissan_altima.nil_make.try(:blam!) }
    provide :nil_model
  end
end

describe Carbon do
  before do
    flush_cache!
  end

  describe :query do
    describe '(one at a time)' do
      it "calculates flight impact" do
        result = Carbon.query('Flight', :origin_airport => 'LAX', :destination_airport => 'SFO', :segments_per_trip => 1, :trips => 1)
        result.decisions.carbon.object.value.must_be_close_to 200, 50
      end
      it "can be used on an object that response to #as_impact_query" do
        Carbon.query(MyNissanAltima.new(2006)).decisions.must_equal MyNissanAltima.new(2006).impact.decisions
      end
      it "gets back characteristics" do
        result = Carbon.query('Flight', :origin_airport => 'LAX', :destination_airport => 'SFO', :segments_per_trip => 1, :trips => 1)
        result.characteristics.origin_airport.description.must_match %r{lax}i
      end
      it "tells you if the query is successful" do
        result = Carbon.query('Flight')
        result.success.must_equal true
      end
      it "is gentle about errors" do
        result = Carbon.query('Monkey')
        result.success.must_equal false
      end
      it "sends timeframe properly" do
        result = Carbon.query('Flight', :timeframe => Timeframe.new(:year => 2009))
        result.timeframe.startDate.must_equal '2009-01-01'
        result.timeframe.endDate.must_equal '2010-01-01'
      end
      it "sends key properly" do
        with_web_mock do
          WebMock.stub_request(:post, 'http://impact.brighterplanet.com/flights.json').with(:body => hash_including(:key => 'carbon_test')).to_return(:status => 500, :body => 'default')
          WebMock.stub_request(:post, 'http://impact.brighterplanet.com/flights.json').with(:body => hash_including(:key => 'carbon_test1')).to_return(:status => 500, :body => 'A')
          WebMock.stub_request(:post, 'http://impact.brighterplanet.com/flights.json').with(:body => hash_including(:key => 'carbon_test2')).to_return(:status => 500, :body => 'B')
          Carbon.query('Flight', :key => 'carbon_test2').errors.first.must_equal 'B'
          Carbon.query('Flight').errors.first.must_equal 'default'
          Carbon.query('Flight', :key => 'carbon_test1').errors.first.must_equal 'A'
        end
      end
      it "allows choosing domain" do
        with_web_mock do
          WebMock.stub_request(:post, 'http://impact.brighterplanet.com/flights.json').to_return(:status => 500, :body => 'used impact')
          WebMock.stub_request(:post, 'http://foo.brighterplanet.com/flights.json').to_return(:status => 500, :body => 'used foo')
          Carbon.query('Flight', :domain => 'http://foo.brighterplanet.com').errors.first.must_equal 'used foo'
          Carbon.query('Flight').errors.first.must_equal 'used impact'
        end
      end
      it "raises ArgumentError if args are bad" do
        lambda {
          Carbon.query(['Flight'])
        }.must_raise ArgumentError
      end
    end
    describe '(in parallel)' do
      before do
        flunk if ENV['SKIP_MULTI'] == 'true'
        @queries = []
        @queries << ['Flight', {:origin_airport => 'LAX', :destination_airport => 'SFO', :segments_per_trip => 1, :trips => 1}]
        @queries << ['Flight', {:origin_airport => 'MSN', :destination_airport => 'ORD', :segments_per_trip => 1, :trips => 1}]
        @queries << ['Flight', {:origin_airport => 'IAH', :destination_airport => 'DEN', :segments_per_trip => 1, :trips => 1}]
        @queries << ['RailTrip', {:distance => 25}]
        @queries << ['RailTrip', {:rail_class => 'commuter'}]
        @queries << ['RailTrip', {:rail_traction => 'electric'}]
        @queries << ['AutomobileTrip', {:make => 'Nissan', :model => 'Altima'}]
        @queries << ['AutomobileTrip', {:make => 'Toyota', :model => 'Prius'}]
        @queries << ['AutomobileTrip', {:make => 'Ford', :model => 'Taurus'}]
        @queries << ['Residence', {:urbanity => 'City'}]
        @queries << ['Residence', {:zip_code => '53703'}]
        @queries << ['Residence', {:bathrooms => 4}]
        @queries << ['Monkey', {:bananas => '1'}]
        @queries << ['Monkey', {:bananas => '2'}]
        @queries << ['Monkey', {:bananas => '3'}]
        @queries = @queries.sort_by { rand }
      end
      it "is easy to use" do
        flight = ['Flight']
        rail_trip = ['RailTrip']
        results = Carbon.query([flight, rail_trip])
        results[flight].decisions.must_equal Carbon.query('Flight').decisions
        results[rail_trip].decisions.must_equal Carbon.query('RailTrip').decisions
      end
      it "doesn't hang up on 0 queries" do
        Timeout.timeout(0.5) { Carbon.query([]) }.must_equal(Hash.new)
      end
      it "can be used on objects that respond to #as_impact_query" do
        Carbon.query([MyNissanAltima.new(2001), MyNissanAltima.new(2006)]).values.map(&:decisions).map(&:carbon).map(&:object).map(&:value).must_equal Carbon.query([MyNissanAltima.new(2001).as_impact_query, MyNissanAltima.new(2006).as_impact_query]).values.map(&:decisions).map(&:carbon).map(&:object).map(&:value)
      end
      it "runs multiple queries at once" do
        reference_results = @queries.inject({}) do |memo, query|
          memo[query] = Carbon.query(*query)
          memo
        end
        ts = []
        3.times do
          ts << Thread.new do
            flush_cache! # important!
            multi_results = Carbon.query(@queries)
            error_count = 0
            multi_results.each do |query, result|
              if result.success
                result.decisions.carbon.object.value.must_be :>, 0
                result.decisions.carbon.object.value.must_be :<, 10_000
              else
                error_count += 1
              end
            end
            error_count.must_equal 3
            reference_results.each do |query, reference_result|
              if reference_result.success
                multi_results[query].decisions.must_equal reference_result.decisions
              else
                multi_results[query].must_equal reference_result
              end
            end
          end
        end
        ts.each do |t|
          t.join
        end
      end
      it "is faster than single threaded" do
        # warm up the cache on the other end
        @queries.each { |query| Carbon.query(*query) }
        flush_cache! # important!
        single_threaded_time = ::Benchmark.realtime do
          @queries.each { |query| Carbon.query(*query) }
        end
        flush_cache! # important!
        multi_threaded_time = ::Benchmark.realtime do
          Carbon.query(@queries)
        end
        cached_single_threaded_time = ::Benchmark.realtime do
          @queries.each { |query| Carbon.query(*query) }
        end
        cached_multi_threaded_time = ::Benchmark.realtime do
          Carbon.query(@queries)
        end
        multi_threaded_time.must_be :<, single_threaded_time
        cached_single_threaded_time.must_be :<, multi_threaded_time
        cached_multi_threaded_time.must_be :<, multi_threaded_time
        $stderr.puts "   Multi-threaded was #{((single_threaded_time - multi_threaded_time) / single_threaded_time * 100).round}% faster than single-threaded"
        $stderr.puts "   Cached single-threaded was #{((multi_threaded_time - cached_single_threaded_time) / multi_threaded_time * 100).round}% faster than uncached multi-threaded"
        $stderr.puts "   Cached multi-threaded was #{((multi_threaded_time - cached_multi_threaded_time) / multi_threaded_time * 100).round}% faster than uncached multi-threaded"
      end
      it "safely uniq's and caches queries" do
        reference_results = @queries.inject({}) do |memo, query|
          memo[query] = Carbon.query(*query)
          memo
        end
        flush_cache! # important!
        3.times do
          multi_results = Carbon.query(@queries)
          reference_results.each do |query, reference_result|
            if reference_result.success
              multi_results[query].decisions.must_equal reference_result.decisions
            else
              multi_results[query].must_equal reference_result
            end
          end
        end
      end
    end
  end

  describe :method_signature do
    it "recognizes emitter_param" do
      Carbon.method_signature('Flight').must_equal :query_array
      Carbon.method_signature('Flight', :origin_airport => 'LAX').must_equal :query_array
      Carbon.method_signature(:flight).must_equal :query_array
      Carbon.method_signature(:flight, :origin_airport => 'LAX').must_equal :query_array
    end
    it "recognizes o" do
      Carbon.method_signature(MyNissanAltima.new(2006)).must_equal :o
    end
    it "recognizes os" do
      Carbon.method_signature([MyNissanAltima.new(2001)]).must_equal :os
      Carbon.method_signature([['Flight']]).must_equal :os
      Carbon.method_signature([['Flight', {:origin_airport => 'LAX'}]]).must_equal :os
      Carbon.method_signature([['Flight'], ['Flight']]).must_equal :os
      Carbon.method_signature([['Flight', {:origin_airport => 'LAX'}], ['Flight', {:origin_airport => 'LAX'}]]).must_equal :os
      [MyNissanAltima.new(2006), ['Flight'], ['Flight', {:origin_airport => 'LAX'}]].permutation.each do |p|
        Carbon.method_signature(p).must_equal :os
      end
    end
    it "does not want splats for concurrent queries" do
      Carbon.method_signature(['Flight'], ['Flight']).must_be_nil
      Carbon.method_signature(MyNissanAltima.new(2001), MyNissanAltima.new(2001)).must_be_nil
      [MyNissanAltima.new(2006), ['Flight'], ['Flight', {:origin_airport => 'LAX'}]].permutation.each do |p|
        Carbon.method_signature(*p).must_be_nil
      end
    end
    it "does not like weirdness" do
      Carbon.method_signature('Flight', 'Flight').must_be_nil
      Carbon.method_signature('Flight', ['Flight']).must_be_nil
      Carbon.method_signature(['Flight'], 'Flight').must_be_nil
      Carbon.method_signature(['Flight', 'Flight']).must_be_nil
      Carbon.method_signature(['Flight', ['Flight']]).must_be_nil
      Carbon.method_signature([['Flight'], 'Flight']).must_be_nil
      Carbon.method_signature(MyNissanAltima.new(2001), [MyNissanAltima.new(2001)]).must_be_nil
      Carbon.method_signature([MyNissanAltima.new(2001)], MyNissanAltima.new(2001)).must_be_nil
      Carbon.method_signature([MyNissanAltima.new(2001)], [MyNissanAltima.new(2001)]).must_be_nil
      Carbon.method_signature([MyNissanAltima.new(2001), [MyNissanAltima.new(2001)]]).must_be_nil
      Carbon.method_signature([[MyNissanAltima.new(2001)], MyNissanAltima.new(2001)]).must_be_nil
      Carbon.method_signature([[MyNissanAltima.new(2001)], [MyNissanAltima.new(2001)]]).must_be_nil
    end
  end

  describe "mixin" do
    describe :emit_as do
      it "overwrites old emit_as blocks" do
        eval %{class MyFoo; include Carbon; end}
        MyFoo.emit_as('Automobile') { provide(:make) }
        Carbon::Registry.instance['MyFoo'].characteristics.keys.must_equal [:make]
        MyFoo.emit_as('Automobile') { provide(:model) }
        Carbon::Registry.instance['MyFoo'].characteristics.keys.must_equal [:model]
      end
    end
    describe '#as_impact_query' do
      it "sets up an query to be run by Carbon.query" do
        a = MyNissanAltima.new(2006)
        a.as_impact_query.must_equal ["Automobile", {:make=>"Nissan", :model=>"Altima", :year=>2006, "automobile_fuel[code]"=>"R"}]
      end
      it "only includes non-nil params" do
        a = MyNissanAltima.new(2006)
        a.as_impact_query[1].keys.must_include :year
        a.as_impact_query[1].keys.wont_include :nil_model
        a.as_impact_query[1].keys.wont_include :nil_make
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
      it "takes timeframe" do
        impact_2010 = MyNissanAltima.new(2006).impact(:timeframe => Timeframe.new(:year => 2010))
        impact_2011 = MyNissanAltima.new(2006).impact(:timeframe => Timeframe.new(:year => 2011))
        impact_2010.timeframe.startDate.must_equal '2010-01-01'
        impact_2011.timeframe.startDate.must_equal '2011-01-01'
      end
    end
  end
end
