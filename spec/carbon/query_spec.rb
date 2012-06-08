require 'helper'
require 'carbon/query'
require 'my_nissan_altima'

describe Carbon::Query do
  let(:query) { Carbon::Query.new 'Flight' }

  describe '.make' do
    it 'makes a single query from standard arguments' do
      queries = Carbon::Query.make('Flight', :origin_airport => 'LAX', :destination_airport => 'SFO', :segments_per_trip => 1, :trips => 1)
      queries.length.should == 1
      queries.first.should be_a(Carbon::Query)
    end
    it 'makes a single query from a Carbonized object' do
      queries = Carbon::Query.make MyNissanAltima.new(2009)
      queries.length.should == 1
      queries.first.should be_a(Carbon::Query)
    end
    it 'makes a list of queries from an array of standard params' do
      queries = Carbon::Query.make [['Flight'], ['Flight']]
      queries.length.should == 2
      queries.first.should be_a(Carbon::Query)
      queries.first.emitter.should == 'Flight'
      queries.last.should be_a(Carbon::Query)
    end
    it 'makes a list of queries from an array of objects' do
      queries = Carbon::Query.make [MyNissanAltima.new(2009), MyNissanAltima.new(2009)]
      queries.length.should == 2
      queries.first.should be_a(Carbon::Query)
      queries.first.emitter.should == 'Automobile'
      queries.last.should be_a(Carbon::Query)
      queries.last.emitter.should == 'Automobile'
    end
    it 'makes a list of queries from an array of params and objects' do
      queries = Carbon::Query.make [['Flight'], MyNissanAltima.new(2009)]
      queries.length.should == 2
      queries.first.should be_a(Carbon::Query)
      queries.last.should be_a(Carbon::Query)
    end
    it 'rejects invalid arguments' do
      expect do
        Carbon::Query.make MyNissanAltima.new(2001), MyNissanAltima.new(2000)
      end.should raise_error(ArgumentError)
    end
  end

  describe '#as_impact_query' do
    it 'sets up an query to be run by Carbon.query' do
      a = MyNissanAltima.new(2006)
      a.as_impact_query.should == ["Automobile", {:make=>"Nissan", :model=>"Altima", :year=>2006, "automobile_fuel[code]"=>"R", :key=>Carbon.key}]
    end
    it 'only includes non-nil params' do
      a = MyNissanAltima.new(2006)
      a.as_impact_query[1].keys.should include(:year)
      a.as_impact_query[1].keys.should_not include(:nil_model)
      a.as_impact_query[1].keys.should_not include(:nil_make)
    end
    it 'includes Carbon.key' do
      begin
        random_key = rand(1e11)
        old_carbon_key = Carbon.key
        Carbon.key = random_key
        a = MyNissanAltima.new(2006)
        a.as_impact_query[1][:key].should == random_key
      ensure
        Carbon.key = old_carbon_key
      end
    end
    it "allows key to be set" do
      begin
        random_key = rand(1e11)
        old_carbon_key = Carbon.key
        Carbon.key = random_key
        a = MyNissanAltima.new(2006)
        a.as_impact_query(:key => 'i want to use this key!')[1][:key].should == 'i want to use this key!'
      ensure
        Carbon.key = old_carbon_key
      end
    end

  end

  describe '.method_signature' do
    it 'recognizes emitter_param' do
      Carbon::Query.method_signature('Flight').should == :plain_query
      Carbon::Query.method_signature('Flight', :origin_airport => 'LAX').should == :plain_query
      Carbon::Query.method_signature(:flight).should == :plain_query
      Carbon::Query.method_signature(:flight, :origin_airport => 'LAX').should == :plain_query
    end
    it 'recognizes an object' do
      Carbon::Query.method_signature(MyNissanAltima.new(2006)).should == :obj
    end
    it 'recognizes an array of signatures' do
      Carbon::Query.method_signature([MyNissanAltima.new(2001)]).should == :array
      Carbon::Query.method_signature([['Flight']]).should == :array
      Carbon::Query.method_signature([['Flight', {:origin_airport => 'LAX'}]]).should == :array
      Carbon::Query.method_signature([['Flight'], ['Flight']]).should == :array
      Carbon::Query.method_signature([['Flight', {:origin_airport => 'LAX'}], ['Flight', {:origin_airport => 'LAX'}]]).should == :array
      [MyNissanAltima.new(2006), ['Flight'], ['Flight', {:origin_airport => 'LAX'}]].permutation.each do |p|
        Carbon::Query.method_signature(p).should == :array
      end
    end
    it "does not accept splats for concurrent queries" do
      Carbon::Query.method_signature(['Flight'], ['Flight']).should be_nil
      Carbon::Query.method_signature(MyNissanAltima.new(2001), MyNissanAltima.new(2001)).should be_nil
      [MyNissanAltima.new(2006), ['Flight'], ['Flight', {:origin_airport => 'LAX'}]].permutation.each do |p|
        Carbon::Query.method_signature(*p).should be_nil
      end
    end
    it "does not like weirdness" do
      Carbon::Query.method_signature('Flight', 'Flight').should be_nil
      Carbon::Query.method_signature('Flight', ['Flight']).should be_nil
      Carbon::Query.method_signature(['Flight'], 'Flight').should be_nil
      Carbon::Query.method_signature(['Flight', 'Flight']).should be_nil
      Carbon::Query.method_signature(['Flight', ['Flight']]).should be_nil
      Carbon::Query.method_signature([['Flight'], 'Flight']).should be_nil
      Carbon::Query.method_signature(MyNissanAltima.new(2001), [MyNissanAltima.new(2001)]).should be_nil
      Carbon::Query.method_signature([MyNissanAltima.new(2001)], MyNissanAltima.new(2001)).should be_nil
      Carbon::Query.method_signature([MyNissanAltima.new(2001)], [MyNissanAltima.new(2001)]).should be_nil
      Carbon::Query.method_signature([MyNissanAltima.new(2001), [MyNissanAltima.new(2001)]]).should be_nil
      Carbon::Query.method_signature([[MyNissanAltima.new(2001)], MyNissanAltima.new(2001)]).should be_nil
      Carbon::Query.method_signature([[MyNissanAltima.new(2001)], [MyNissanAltima.new(2001)]]).should be_nil
    end
  end

  describe '.perform' do
    it 'returns a single result for a single query' do
      VCR.use_cassette 'Flight', :record => :once do
        Carbon::Query.perform('Flight').should be_a(Hashie::Mash)
      end
    end
    it 'returns a hash of queries and results for multiple queries' do
      results = nil
      VCR.use_cassette 'Flight and Automobile', :record => :once do
        results = Carbon::Query.perform([['Flight'], ['Automobile']])
      end
      results.length.should == 2
      results.keys.each do |key|
        key.should be_a(Array)
      end
      results.values.each do |val|
        val.should be_a(Hashie::Mash)
      end
    end
  end
end

