require 'singleton'

module Carbon
  # Used internally to hold the information about how each class that has called `emit_as`.
  class Registry < ::Hash
    include ::Singleton

    # Used internally to record the emitter and parameters (characteristics) provided by a class that has called `emit_as`.
    # Can't use my magic sprinkles (::Struct) because of yardoc
    # @private
    class Registration < Struct.new(:emitter, :characteristics)
    end

    # Used internally when instance-eval'ing the +emit_as+ DSL.
    class Registrar
      # @private
      def initialize(klass, emitter)
        @klass = klass
        Registry.instance[klass.name] = Registration.new
        Registry.instance[klass.name].emitter = emitter
        Registry.instance[klass.name].characteristics = {}
      end
      
      # Indicate that you will send in a piece of data about the emitter.
      #
      # Called inside of {Carbon::ClassMethods#emit_as} blocks.
      #
      # @param [Symbol] method_id What method to call to get the value in question.
      #
      # @option translation_options [Symbol] :as (name of the method) If your method name does not match the Brighter Planet characteristic name.
      # @option translation_options [Symbol] :key (a number of columns) What you are keying on. By default, we do a fuzzy match against a number of fields, including full names and various codes.
      #
      # @return [nil]
      #
      # @note It's suggested that you use {http://api.rubyonrails.org/classes/Object.html#method-i-try Object#try} to cheaply avoid +undefined method `iata_code` for nil:NilClass+. It will be available because this class includes +active_support/core_ext+ anyway.
      #
      # @yield [] Pass a block for the common use case of calling a method on a object.
      #
      # Things to note in the MyFlight example:
      #
      # * Sending +:origin+ to Brighter Planet *as* +:origin_airport+. Otherwise Brighter Planet won't recognize +:origin+.
      # * Saying we're *keying* on one code or another. Otherwise Brighter Planet will first try against full names and possibly other columns.
      # * Giving *blocks* to pull codes from +MyAircraft+ and +MyAirline+ objects. Otherwise you might get a querystring like +airline[iata_code]=#<MyAirline [...]>+
      #
      # @example The canonical MyFlight example
      #   emit_as 'Flight' do
      #     provide :segments_per_trip
      #     provide :trips
      #     provide :origin, :as => :origin_airport, :key => :iata_code
      #     provide :destination, :as => :destination_airport, :key => :iata_code
      #     provide(:airline, :key => :iata_code) { |f| f.airline.try(:iata_code) }
      #     provide(:aircraft, :key => :icao_code) { { |f| f.aircraft.try(:icao_code) }
      #   end
      #
      # @example Your method is named one thing but should be sent +:as+ something else.
      #   provide :my_distance, :as => :distance
      #
      # @example You are keying on something well-known like {http://en.wikipedia.org/wiki/Airline_codes IATA airline codes}.
      #   provide(:airline, :key => :iata_code) { |f| f.airline.try(:iata_code) }
      #
      # @example Better to use a block
      #   provide(:airline, :key => :iata_code) { |f| f.airline.try(:iata_code) }
      #   # is equivalent to
      #   def airline_iata_code
      #     airline.iata_code
      #   end
      #   provide :airline_iata_code, :as => :airline, :key => :iata_code
      def provide(method_id, translation_options = {}, &blk)
        translation_options = translation_options.dup
        if block_given?
          translation_options[:blk] = blk
        end
        Registry.instance[@klass.name].characteristics[method_id] = translation_options
      end
    end
  end
end
