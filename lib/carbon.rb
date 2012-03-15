require 'active_support/core_ext'

require 'carbon/registry'
require 'carbon/future'

module Carbon
  DOMAIN = 'http://impact.brighterplanet.com'
  CONCURRENCY = 16

  # @private
  # Make sure there are no warnings about class vars.
  @@key = nil unless defined?(@@key)

  # Set the Brighter Planet API key that you can get from http://keys.brighterplanet.com
  #
  # @param [String] key The alphanumeric key.
  #
  # @return [nil]
  def Carbon.key=(key)
    @@key = key
    nil
  end

  # Get the key you've set.
  #
  # @return [String] The key you set.
  def Carbon.key
    @@key
  end

  # Get impact estimates from Brighter Planet CM1; low-level method that does _not_ require you to define {Carbon::ClassMethods#emit_as} blocks; just pass emitter/param or objects that respond to +#as_impact_query+.
  #
  # Return values are {http://rdoc.info/github/intridea/hashie/Hashie/Mash Hashie::Mash} objects because they are a simple way to access a deeply nested response.
  #
  # Here's a map of what's included in a response:
  #
  #     certification
  #     characteristics.{}.description
  #     characteristics.{}.object
  #     compliance.[]
  #     decisions.{}.description
  #     decisions.{}.methodology
  #     decisions.{}.object
  #     emitter
  #     equivalents.{}
  #     errors.[]
  #     methodology
  #     scope
  #     timeframe.endDate
  #     timeframe.startDate
  #
  # @overload query(emitter, params)
  #   Simplest form.
  #   @param [String] emitter The {http://impact.brighterplanet.com/emitters.json emitter name}.
  #   @param [optional, Hash] params Characteristics like airline/airport/etc., your API key (if you didn't set it globally), timeframe, compliance, etc.
  #   @option params [Timeframe] :timeframe (Timeframe.this_year) What time period to focus the calculation on. See {https://github.com/rossmeissl/timeframe timeframe} documentation.
  #   @option params [Array<Symbol>] :comply ([]) What {http://impact.brighterplanet.com/protocols.json calculation protocols} to require.
  #   @option params [String, Numeric] <i>characteristic</i> Pieces of data about an emitter. The {http://impact.brighterplanet.com/flights/options Flight characteristics API} lists valid keys like +:aircraft+, +:origin_airport+, etc.
  #   @return [Hashie::Mash] The API response, contained in an easy-to-use +Hashie::Mash+
  #
  # @overload query(o)
  #   Pass in a single query-able object.
  #   @param [#as_impact_query] o An object that responds to +#as_impact_query+, generally because you've declared {Carbon::ClassMethods#emit_as} on its parent class.
  #   @return [Hashie::Mash] The API response, contained in an easy-to-use +Hashie::Mash+
  #
  # @overload query(os)
  #   Get multiple impact estimates for arrays and/or query-able objects concurrently.
  #   @param [Array<Array, #as_impact_query>] os An array of arrays in +[emitter, params]+ format and/or objects that respond to +#as_impact_query+.
  #   @return [Array<Hashie::Mash>] An array of +Hashie::Mash+ objects in the same order.
  #
  # @note We make up to 16 requests concurrently (hardcoded, per the Brighter Planet Terms of Service) and it can be more than 90% faster than running queries serially!
  #
  # @note Using concurrency on JRuby, you may get errors like SOCKET: SET COMM INACTIVITY UNIMPLEMENTED 10 because under the hood we're using {https://github.com/igrigorik/em-http-request em-http-request}, which suffers from {https://github.com/eventmachine/eventmachine/issues/155 an issue with +pending_connect_timeout+}.
  #
  # @example A flight taken in 2009
  #   Carbon.query('Flight', :origin_airport => 'MSN', :destination_airport => 'ORD', :date => '2009-01-01', :timeframe => Timeframe.new(:year => 2009), :comply => [:tcr])
  #
  # @example How do I use a +Hashie::Mash+?
  #   1.8.7 :001 > require 'rubygems'
  #    => true 
  #   1.8.7 :002 > require 'hashie/mash'
  #    => true 
  #   1.8.7 :003 > mash = Hashie::Mash.new(:hello => 'world')
  #    => #<Hashie::Mash hello="world"> 
  #   1.8.7 :004 > mash.hello
  #    => "world" 
  #   1.8.7 :005 > mash['hello']
  #    => "world" 
  #   1.8.7 :006 > mash[:hello]
  #    => "world" 
  #   1.8.7 :007 > mash.keys
  #    => ["hello"] 
  #
  # @example Other examples of what's in the response
  #   my_impact.carbon.object.value
  #   my_impact.characteristics.airline.description
  #   my_impact.equivalents.lightbulbs_for_a_week
  #
  # @example Flights and cars (concurrently, as arrays)
  #   queries = [
  #     ['Flight', {:origin_airport => 'MSN', :destination_airport => 'ORD', :date => '2009-01-01', :timeframe => Timeframe.new(:year => 2009), :comply => [:tcr]}],
  #     ['Flight', {:origin_airport => 'SFO', :destination_airport => 'LAX', :date => '2011-09-29', :timeframe => Timeframe.new(:year => 2011), :comply => [:iso]}],
  #     ['Automobile', {:make => 'Nissan', :model => 'Altima', :timeframe => Timeframe.new(:year => 2008), :comply => [:tcr]}]
  #   ]
  #   Carbon.query(queries)
  #
  # @example Flights and cars (concurrently, as query-able objects)
  #   Carbon.query(MyFlight.all+MyCar.all)
  #
  # @example Cars month-by-month
  #   cars_by_month = MyCar.all.inject([]) do |memo, my_car|
  #     months.each do |first_day_of_the_month|
  #       my_car.as_impact_query(:date => first_day_of_the_month)
  #     end
  #   end
  #   Carbon.query(cars_by_month)
  def Carbon.query(*args)
    case Carbon.method_signature(*args)
    when :query_array
      query_array = args
      future = Future.wrap query_array
      future.result
    when :o
      o = args.first
      future = Future.wrap o
      future.result
    when :os
      os = args.first
      futures = os.map do |o|
        future = Future.wrap o
        future.multi!
        future
      end
      Future.multi(futures).map do |future|
        future.result
      end
    end
  end

  # Determine if a variable is a +[emitter, param]+ style "query"
  # @private
  def Carbon.is_query_array?(query)
    return false unless query.is_a?(::Array)
    return false unless query.first.is_a?(::String) or query.first.is_a?(::Symbol)
    return true if query.length == 1
    return true if query.length == 2 and query.last.is_a?(::Hash)
    false
  end

  # Determine what method signature/overloading/calling style is being used
  # @private
  def Carbon.method_signature(*args)
    first_arg = args.first
    case args.length
    when 1
      if is_query_array?(args)
        # query('Flight')
        :query_array
      elsif first_arg.respond_to?(:as_impact_query)
        # query(my_flight)
        :o
      elsif first_arg.is_a?(::Array) and first_arg.all? { |o| o.respond_to?(:as_impact_query) or is_query_array?(o) }
        # query([my_flight, my_flight])
        :os
      end
    when 2
      if is_query_array?(args)
        # query('Flight', :origin_airport => 'LAX')
        :query_array
      end
    end
  end

  # Called when you +include Carbon+ and adds the class method +emit_as+.
  # @private
  def Carbon.included(klass)
    klass.extend ClassMethods
  end

  # Mixed into any class that includes +Carbon+.
  module ClassMethods
    # DSL for declaring how to represent this class an an emitter.
    #
    # See also {Carbon::Registry::Registrar#provide}.
    #
    # You get this when you +include Carbon+ in a class.
    #
    # @param [String] emitter The {http://impact.brighterplanet.com/emitters.json camelcased emitter name}.
    #
    # @return [nil]
    #
    # @example MyFlight
    #   # A a flight in your data warehouse
    #   class MyFlight
    #     def airline
    #       # ... => MyAirline(:name, :icao_code, ...)
    #     end
    #     def aircraft
    #       # ... => MyAircraft(:name, :icao_code, ...)
    #     end
    #     def origin
    #       # ... => String
    #     end
    #     def destination
    #       # ... => String
    #     end
    #     def segments_per_trip
    #       # ... => Integer
    #     end
    #     def trips
    #       # ... => Integer
    #     end
    #     include Carbon
    #     emit_as 'Flight' do
    #       provide :segments_per_trip
    #       provide :trips
    #       provide :origin, :as => :origin_airport, :key => :iata_code
    #       provide :destination, :as => :destination_airport, :key => :iata_code
    #       provide(:airline, :key => :iata_code) { |f| f.airline.try(:iata_code) }
    #       provide(:aircraft, :key => :icao_code) { { |f| f.aircraft.try(:icao_code) }
    #     end
    #   end
    def emit_as(emitter, &blk)
      emitter = emitter.to_s.singularize.camelcase
      registrar = Registry::Registrar.new self, emitter
      registrar.instance_eval(&blk)
    end
  end

  # A query like what you could pass into +Carbon.query+.
  #
  # @param [Hash] extra_params Anything you want to override.
  #
  # @option extra_params [Timeframe] :timeframe
  # @option extra_params [Array<Symbol>] :comply
  # @option extra_params [String] :key In case you didn't define it globally, or want to use a different one here.
  # @option extra_params [String, Numeric] <i>characteristic</i> Override pieces of data about an emitter.
  #
  # @return [Array] Something you could pass into +Carbon.query+.
  def as_impact_query(extra_params = {})
    registration = Registry.instance[self.class.name]
    params = registration.characteristics.inject({}) do |memo, (method_id, translation_options)|
      k = translation_options.has_key?(:as) ? translation_options[:as] : method_id
      if translation_options.has_key?(:key)
        k = "#{k}[#{translation_options[:key]}]"
      end
      v = if translation_options.has_key?(:blk)
        translation_options[:blk].call self
      else
        send method_id
      end
      if v.present?
        memo[k] = v
      end
      memo
    end
    [ registration.emitter, params.merge(extra_params) ]
  end

  # Get an impact estimate from Brighter Planet CM1; high-level convenience method that requires a {Carbon::ClassMethods#emit_as} block.
  #
  # You get this when you +include Carbon+ in a class.
  #
  # See {Carbon.query} for an explanation of the return value, a +Hashie::Mash+.
  #
  # @param [Hash] extra_params Anything you want to override.
  #
  # @option extra_params [Timeframe] :timeframe
  # @option extra_params [Array<Symbol>] :comply
  # @option extra_params [String] :key In case you didn't define it globally, or want to use a different one here.
  # @option extra_params [String, Numeric] <i>characteristic</i> Override pieces of data about an emitter.
  #
  # @return [Hashie::Mash]
  #
  # @example Getting impact estimate for MyFlight
  #   ?> my_flight = MyFlight.new([...])
  #   => #<MyFlight [...]>
  #   ?> my_impact = my_flight.impact(:timeframe => Timeframe.new(:year => 2009))
  #   => #<Hashie::Mash [...]>
  #   ?> my_impact.decisions.carbon.object.value
  #   => 1014.92
  #   ?> my_impact.decisions.carbon.object.units
  #   => "kilograms"
  #   ?> my_impact.methodology
  #   => "http://impact.brighterplanet.com/flights?[...]"
  def impact(extra_params = {})
    query_array = as_impact_query extra_params
    future = Future.wrap query_array
    future.result
  end
end
