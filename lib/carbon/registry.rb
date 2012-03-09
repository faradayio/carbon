require 'singleton'

module Carbon
  # Used internally to hold the information about how each class that has called `emit_as`.
  # @private
  class Registry < ::Hash
    include ::Singleton

    # Used internally to record the emitter and parameters (characteristics) provided by a class that has called `emit_as`.
    # @private
    class Registration < ::Struct.new(:emitter, :characteristics)
    end

    # Used internally when instance-eval'ing the `emit_as` DSL.
    # @private
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
      # @param [Symbol] method_id What method to call to get the value in question.
      #
      # @option translation_options [Symbol] :as (name of the method) If your method name does not match the Brighter Planet characteristic name.
      # @option translation_options [Symbol] :key (a number of columns) What you are keying on. By default, we do a fuzzy match against a number of fields, including full names and various codes.
      #
      # @yield [] Pass a block for the common use case of calling a method on a object.
      #
      # @example Your method is named one thing but should be sent +:as+ something else.
      #   provide :my_distance, :as => :distance
      #
      # @example You are keying on something well-known like {http://en.wikipedia.org/wiki/Airline_codes IATA airline codes}.
      #   provide(:airline, :key => :iata_code) { |f| f.airline.iata_code }
      #
      # @example Better to use a block
      #   provide(:airline, :key => :iata_code) { |f| f.airline.iata_code }
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
