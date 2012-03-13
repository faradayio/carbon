require 'net/http'
require 'hashie/mash'
require 'multi_json'
require 'active_support/core_ext'

require 'carbon/registry'

module Carbon
  DOMAIN = 'http://impact.brighterplanet.com'

  # @private
  # Make sure there are no warnings about class vars.
  @@key = nil unless defined?(@@key)

  # Set the Brighter Planet API key that you can get from http://keys.brighterplanet.com
  #
  # @param [String] key The alphanumeric key.
  #
  # @return [nil]
  def self.key=(key)
    @@key = key
  end

  # Get the key you've set.
  #
  # @return [String] The key you set.
  def self.key
    @@key
  end

  # Do a simple query.
  #
  # See the {file:README.html#API_response section about API responses} for an explanation of +Hashie::Mash+.
  #
  # @param [String] emitter The {http://impact.brighterplanet.com/emitters.json camelcased emitter name}.
  # @param [Hash] params Characteristics, your API key (if you didn't set it globally), timeframe, compliance, etc.
  #
  # @option params [Timeframe] :timeframe (Timeframe.this_year) What time period to focus the calculation on. See {https://github.com/rossmeissl/timeframe timeframe} documentation.
  # @option params [Array<Symbol>] :comply ([]) What {http://impact.brighterplanet.com/protocols.json calculation protocols} to require.
  # @option params [String, Numeric] _characteristic_ Pieces of data about an emitter. The {http://impact.brighterplanet.com/flights/options Flight characteristics API} lists valid keys like +:aircraft+, +:origin_airport+, etc.
  #
  # @return [Hashie::Mash] An {file:README.html#API_response API response as documented in the README}
  #
  # @example A flight taken in 2009
  #   Carbon.query('Flight', :origin_airport => 'MSN', :destination_airport => 'ORD', :date => '2009-01-01', :timeframe => Timeframe.new(:year => 2009), :comply => [:tcr])
  def self.query(emitter, params = {})
    params ||= {}
    params = params.reverse_merge(:key => key) if key
    uri = ::URI.parse("#{DOMAIN}/#{emitter.underscore.pluralize}.json")
    raw_response = ::Net::HTTP.post_form(uri, params)
    response = ::Hashie::Mash.new
    case raw_response
    when ::Net::HTTPSuccess
      response.status = raw_response.code.to_i
      response.success = true
      response.merge! ::MultiJson.decode(raw_response.body)
    else
      response.status = raw_response.code.to_i
      response.success = false
      response.error_body = raw_response.respond_to?(:body) ? raw_response.body : ''
      response.errors = [raw_response.class.name]
    end
    response
  end

  # Perform many queries in parallel. Can be >90% faster than doing them serially (one after the other).
  #
  # See the {file:README.html#API_response section about API responses} for an explanation of +Hashie::Mash+.
  #
  # @param [Array<Array>] queries Multiple queries like you would pass to {Carbon.query}
  #
  # @return [Array<Hashie::Mash>] An array of {file:README.html#API_response API responses} in the same order as the queries.
  #
  # @note Not supported on JRuby because it uses {https://github.com/igrigorik/em-http-request em-http-request}, which suffers from {https://github.com/eventmachine/eventmachine/issues/155 an issue with +pending_connect_timeout+}.
  #
  # @example Two flights and an automobile trip
  #   queries = [
  #     ['Flight', :origin_airport => 'MSN', :destination_airport => 'ORD', :date => '2009-01-01', :timeframe => Timeframe.new(:year => 2009), :comply => [:tcr]],
  #     ['Flight', :origin_airport => 'SFO', :destination_airport => 'LAX', :date => '2011-09-29', :timeframe => Timeframe.new(:year => 2011), :comply => [:iso]],
  #     ['AutomobileTrip', :make => 'Nissan', :model => 'Altima', :timeframe => Timeframe.new(:year => 2008), :comply => [:tcr]]
  #   ]
  #   Carbon.multi(queries)
  def self.multi(queries)
    require 'em-http-request'
    unsorted = {}
    multi = ::EventMachine::MultiRequest.new
    ::EventMachine.run do
      queries.each_with_index do |(emitter, params), query_idx|
        params ||= {}
        params = params.reverse_merge(:key => key) if key
        multi.add query_idx, ::EventMachine::HttpRequest.new(DOMAIN).post(:path => "/#{emitter.underscore.pluralize}.json", :body => params)
      end
      multi.callback do
        multi.responses[:callback].each do |query_idx, http|
          response = ::Hashie::Mash.new
          response.status = http.response_header.status
          if (200..299).include?(response.status)
            response.success = true
            response.merge! ::MultiJson.decode(http.response)
          else
            response.success = false
            response.errors = [http.response]
          end
          unsorted[query_idx] = response
        end
        multi.responses[:errback].each do |query_idx, http|
          response = ::Hashie::Mash.new
          response.status = http.response_header.status
          response.success = false
          response.errors = ['Timeout or other network error.']
          unsorted[query_idx] = response
        end
        ::EventMachine.stop
      end
    end
    unsorted.sort_by do |query_idx, _|
      query_idx
    end.map do |_, response|
      response
    end
  end

  # Called when you +include Carbon+ and adds the class method +emit_as+.
  # @private
  def self.included(klass)
    klass.extend ClassMethods
  end

  # Mixed into any class that includes +Carbon+.
  module ClassMethods
    # DSL for declaring how to represent this class an an emitter.
    #
    # You get this when you +include Carbon+ in a class.
    #
    # @param [String] emitter The {http://impact.brighterplanet.com/emitters.json camelcased emitter name}.
    #
    # @return [nil]
    #
    # Things to note in the MyFlight example:
    #
    # * Sending +:origin+ to Brighter Planet *as* +:origin_airport+. Otherwise Brighter Planet won't recognize +:origin+.
    # * Saying we're *keying* on one code or another. Otherwise Brighter Planet will first try against full names and possibly other columns.
    # * Giving *blocks* to pull codes from +MyAircraft+ and +MyAirline+ objects. Otherwise you might get a querystring like +airline[iata_code]=#<MyAirline [...]>+
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

  # What will be sent to Brighter Planet CM1.
  # @private
  def impact_params
    return unless registration = Registry.instance[self.class.name]
    registration.characteristics.inject({}) do |memo, (method_id, translation_options)|
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
  end

  # Get an impact estimate from Brighter Planet CM1.
  #
  # You get this when you +include Carbon+ in a class.
  #
  # The return value is a {http://rdoc.info/github/intridea/hashie/Hashie/Mash Hashie::Mash} because it's a simple way to access a deep response object.
  #
  # Here's a map of what's included in a response:
  #
  #       certification
  #       characteristics.{}.description
  #       characteristics.{}.object
  #       compliance.[]
  #       decisions.{}.description
  #       decisions.{}.methodology
  #       decisions.{}.object
  #       emitter
  #       equivalents.{}
  #       errors.[]
  #       methodology
  #       scope
  #       timeframe.endDate
  #       timeframe.startDate
  #
  # @param [Hash] extra_params Anything that your +emit_as+ won't include.
  #
  # @option extra_params [Timeframe] :timeframe
  # @option extra_params [Array<Symbol>] :comply
  # @option extra_params [String] :key In case you didn't define it globally, or want to use a different one here.
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
  #
  # @example How do I use a Hashie::Mash?
  #   ?> mash['hello']
  #   => "world"
  #   ?> mash.hello
  #   => "world"
  #   ?> mash.keys
  #   => ["hello"]
  #
  # @example Other examples of what's in the response
  #   my_impact.carbon.object.value
  #   my_impact.characteristics.airline.description
  #   my_impact.equivalents.lightbulbs_for_a_week
  def impact(extra_params = {})
    return unless registration = Registry.instance[self.class.name]
    Carbon.query registration.emitter, impact_params.merge(extra_params)
  end
end
