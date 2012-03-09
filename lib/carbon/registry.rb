require 'singleton'

module Carbon
  # Used internally to hold the information about how each class that has called `emit_as`.
  class Registry < ::Hash
    include ::Singleton

    # Used internally to record the emitter and parameters (characteristics) provided by a class that has called `emit_as`.
    class Registration < ::Struct.new(:emitter, :characteristics)
    end

    # Used internally when instance-eval'ing the `emit_as` DSL.
    class Registrar
      def initialize(klass, emitter)
        @klass = klass
        Registry.instance[klass.name] = Registration.new
        Registry.instance[klass.name].emitter = emitter
        Registry.instance[klass.name].characteristics = {}
      end
      
      # Indicate that you will send in a piece of data about the emitter.
      #
      # The idea:
      # * Check the parameter name Brighter Planet expects to receive. Use `:as` if your method is named one thing but should be sent as something else.
      # * Check the range of acceptable values at the model pages (for example, http://impact.brighterplanet.com/models/flight). Use `:key` if you are keying on something other than the default, for example IATA airline codes like "COA". By default, we match your input for airline against `name` like "Continental Airlines" and telling us what you're keying on will improve your results.
      #
      # @param [Symbol] method_id What method to call to get the value in question.
      #
      # @option translation_options [Symbol] :as If your method name does not match the Brighter Planet characteristic name. For example, <tt>provide :my_distance, :as => :distance</tt>.
      # @option translation_options [Symbol] :key What you are keying on. By default, we do a fuzzy match against a number of columns. For example, <tt>provide :airline_iata_code, :as => :airline, :key => :iata_code</tt>.
      def provide(method_id, translation_options = {})
        Registry.instance[@klass.name].characteristics[method_id] = translation_options
      end
    end
  end
end
