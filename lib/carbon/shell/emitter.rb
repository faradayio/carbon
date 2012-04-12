require 'uri'
require 'net/http'
require 'conversions'
require 'cache_method'

module Carbon
  class Shell
    # @private
    class Emitter < Bombshell::Environment
      class << self
        # @private
        def characteristics(emitter)
          ::MultiJson.decode ::Net::HTTP.get(::URI.parse("http://impact.brighterplanet.com/#{emitter.underscore.pluralize}/options.json"))
        rescue
          # oops
        end
        cache_method :characteristics, 300
      end

      include Bombshell::Shell
      include Carbon
      
      # @private
      def initialize(name, input = {})
        @emitter = name.to_s.singularize.camelcase
        @input = input
        if characteristics = Emitter.characteristics(@emitter)
          characteristics.each do |characteristic|
            instance_eval <<-meth
              def #{characteristic}(arg = nil)
                if arg
                  @input[:#{characteristic}] = arg.to_s.strip
                  emission
                else
                  @input[:#{characteristic}]
                end
              end
            meth
          end
          provisions = characteristics.map { |k| "provide :#{k}"}.join('; ')
          emit_as_block = "emit_as(:#{name}) { #{provisions} }"
          self.class.class_eval emit_as_block
          emission
        else
          puts "  => Sorry, characteristics couldn't be retrieved for #{@emitter.underscore.pluralize}. Please try again later."
          done
        end
      end
      
      # @private
      def timeframe(t = nil)
        if t
          @timeframe = t
          emission
        elsif @timeframe
          puts '  => ' + @timeframe
        else
          puts '  => (defaults to current year)'
        end
      end
      
      # @private
      def emission
        puts "  => #{emission_in_kilograms} kg CO2e"
      end
      
      # @private
      def emission_in_kilograms
        impact(:timeframe => @timeframe).decisions.carbon.object.value
      end
      
      # @private
      def lbs
        puts "  => #{emission_in_kilograms.kilograms.to :pounds} lbs CO2e"
      end
      alias :pounds :lbs
      
      # @private
      def tons
        puts "  => #{emission_in_kilograms.kilograms.to :tons} lbs CO2e"
      end
      
      # @private
      def characteristics
        if @input.empty?
          puts "  => (none)"
        else
          first = true
          @input.each_pair do |key, value|
            if first
              puts "  => #{key}: #{value}"
              first = false
            else
              puts "     #{key}: #{value}"
            end
          end
        end
      end
      
      # @private
      def url
        puts "  => #{impact(:timeframe => @timeframe).methodology}"
      end
      
      # @private
      def methodology
        first = true
        impact(:timeframe => @timeframe).decisions.each do |name, report|
          if first
            w = '  => '
            first = false
          else
            w = '     '
          end
          puts w + "#{name}: #{report.methodology}"
        end
      end
      
      # @private
      def reports
        first = true
        impact(:timeframe => @timeframe).decisions.each do |name, report|
          if first
            w = '  => '
            first = false
          else
            w = '     '
          end
          puts w + "#{name}: #{report.object.inspect}"
        end
      end
      
      # @private
      def help
        puts "  => #{Emitter.characteristics(@emitter).join ', '}"
      end
      
      prompt_with do |emitter|
        if emitter._timeframe
          "#{emitter._name}[#{emitter._timeframe}]*"
        else          
          "#{emitter._name}*"
        end
      end
      
      # @private
      def _name
        @emitter
      end
      
      # @private
      def _timeframe
        @timeframe
      end
      
      # @private
      def inspect
        "#<Emitter[#{@emitter}]: #{@input.inspect}>"
      end
      
      # @private
      def done
        $emitters[@emitter] ||= []
        $emitters[@emitter] << @input
        puts "  => Saved as #{@emitter} ##{$emitters[@emitter].length - 1}"
        quit
      end
    end
  end
end
