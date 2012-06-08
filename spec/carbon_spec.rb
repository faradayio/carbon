require 'helper'
require 'timeframe'
require 'benchmark'

require 'my_nissan_altima'

Thread.abort_on_exception = true
Carbon.key = 'carbon_test'

describe Carbon do
  before do
    flush_cache!
  end

  describe '.query' do
    context 'serial' do
      it "calculates flight impact" do
        VCR.use_cassette 'LAX->SFO flight', :record => :once do
          result = Carbon.query('Flight', :origin_airport => 'LAX', :destination_airport => 'SFO', :segments_per_trip => 1, :trips => 1)
          result.decisions.carbon.object.value.should be_within(50).of(200)
        end
      end
      it "can be used on an object that responds to #as_impact_query" do
        VCR.use_cassette '2006 Altima', :record => :once do
          Carbon.query(MyNissanAltima.new(2006)).decisions.should == MyNissanAltima.new(2006).impact.decisions
        end
      end
      it "gets back characteristics" do
        VCR.use_cassette 'LAX->SFO flight', :record => :once do
          result = Carbon.query('Flight', :origin_airport => 'LAX', :destination_airport => 'SFO', :segments_per_trip => 1, :trips => 1)
          result.characteristics.origin_airport.description.should =~ %r{lax}i
        end
      end
      it "tells you if the query is successful" do
        VCR.use_cassette 'Flight', :record => :once do
          result = Carbon.query('Flight')
          result.success.should be_true
        end
      end
      it "is gentle about errors" do
        VCR.use_cassette 'Monkey', :record => :once do
          result = Carbon.query('Monkey')
          result.success.should be_false
        end
      end
      it "sends timeframe properly" do
        VCR.use_cassette 'timeframed flight', :record => :once do
          result = Carbon.query('Flight', :timeframe => Timeframe.new(:year => 2009))
          result.timeframe.should == '2009-01-01/2010-01-01'
        end
      end
      it "sends key properly" do
        VCR.use_cassette 'flight with key 1', :record => :once do
          result = Carbon.query('Flight', :key => 'carbon_test1')
          result.errors.first.should =~ /carbon_test1/
        end
        VCR.use_cassette 'flight with key 2', :record => :once do
          result = Carbon.query('Flight', :key => 'carbon_test2')
          result.errors.first.should =~ /carbon_test2/
        end
      end
      it "allows choosing domain" do
        VCR.use_cassette 'carbon.bp.com flight', :record => :once do
          result = Carbon.query('Flight', :domain => 'http://carbon.brighterplanet.com')
          result.carbon.value.should > 0
        end
      end
      it "raises ArgumentError if args are bad" do
        expect do
          Carbon.query(['Flight'])
        end.should raise_error(ArgumentError)
      end
    end

    context 'in parallel', :multi => true do
      before do
        VCR.turn_off!
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

      after do
        VCR.turn_on!
      end

      it "is easy to use" do
        flight = ['Flight']
        rail_trip = ['RailTrip']
        results = Carbon.query([flight, rail_trip])
        results[flight].decisions.should == Carbon.query('Flight').decisions
        results[rail_trip].decisions.should == Carbon.query('RailTrip').decisions
      end
      it "doesn't hang up on 0 queries" do
        Timeout.timeout(0.5) { Carbon.query([]) }.should ==(Hash.new)
      end
      it "raises if you pass it a block directly" do
        expect do
          Carbon.query([]) { }
        end.should raise_error(ArgumentError)
      end
      it "can be used on objects that respond to #as_impact_query" do
        a = MyNissanAltima.new(2001)
        b = MyNissanAltima.new(2006)
        ab1 = Carbon.query([a, b])
        ab2 = Carbon.query([a.as_impact_query, b.as_impact_query])
        ab1.each do |k, v|
          ab2[k.as_impact_query].should == v
        end
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
                result.decisions.carbon.object.value.should > 0
                result.decisions.carbon.object.value.should < 10_000
              else
                error_count += 1
              end
            end
            error_count.should == 3
            reference_results.each do |query, reference_result|
              if reference_result.success
                multi_results[query].decisions.should == reference_result.decisions
              else
                multi_results[query].should == reference_result
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
        single_threaded_time = Benchmark.realtime do
          @queries.each { |query| Carbon.query(*query) }
        end
        flush_cache! # important!
        multi_threaded_time = Benchmark.realtime do
          Carbon.query(@queries)
        end
        cached_single_threaded_time = Benchmark.realtime do
          @queries.each { |query| Carbon.query(*query) }
        end
        cached_multi_threaded_time = Benchmark.realtime do
          Carbon.query(@queries)
        end
        multi_threaded_time.should < single_threaded_time
        cached_single_threaded_time.should < multi_threaded_time
        cached_multi_threaded_time.should < multi_threaded_time
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
              multi_results[query].decisions.should == reference_result.decisions
            else
              multi_results[query].should == reference_result
            end
          end
        end
      end
    end
  end

  describe "mixin" do
    describe :emit_as do
      it "overwrites old emit_as blocks" do
        eval %{class MyFoo; include Carbon; end}
        MyFoo.emit_as('Automobile') { provide(:make) }
        Carbon::Registry.instance['MyFoo'].characteristics.keys.should == [:make]
        MyFoo.emit_as('Automobile') { provide(:model) }
        Carbon::Registry.instance['MyFoo'].characteristics.keys.should == [:model]
      end
    end
    describe '#impact' do
      it 'calculates a single impact' do
        VCR.use_cassette '2006 Altima', :record => :once do
          impact = MyNissanAltima.new(2006).impact
          impact.decisions.carbon.object.value.should > 0
          impact.characteristics.make.description.should =~ %r{Nissan}i
          impact.characteristics.model.description.should =~ %r{Altima}i
          impact.characteristics.year.description.to_i.should == 2006
          impact.characteristics.automobile_fuel.description.should =~ %r{regular gasoline}
        end
      end
      it 'accepts a timeframe option' do
        VCR.use_cassette '2006 Altima in 2010', :record => :once do
          impact_2010 = MyNissanAltima.new(2006).impact(:timeframe => Timeframe.new(:year => 2010))
          impact_2010.timeframe.should =~ /^2010-01-01/
        end
        VCR.use_cassette '2006 Altima in 2011', :record => :once do
          impact_2011 = MyNissanAltima.new(2006).impact(:timeframe => Timeframe.new(:year => 2011))
          impact_2011.timeframe.should =~ /^2011-01-01/
        end
      end
    end
  end
end
