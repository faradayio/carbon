require 'uri'
require 'net/http'
require 'conversions'

module Carbon
  class Shell
    class Emitter < Bombshell::Environment
      include Bombshell::Shell
      include Carbon
      
      def initialize(name, input = {})
        @emitter = name.to_s.singularize.camelcase
        @input = input
        response = ::Net::HTTP.get_response(::URI.parse("http://impact.brighterplanet.com/#{@emitter.underscore.pluralize}/options.json"))
        if (200..299).include?(response.code.to_i)
          @characteristics = ::MultiJson.decode response.body
          @characteristics.keys.each do |characteristic|
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
          provisions = @characteristics.keys.map { |k| "provide :#{k}"}.join('; ')
          emit_as_block = "emit_as(:#{name}) { #{provisions} }"
          self.class.class_eval emit_as_block
          emission
        else
          puts "  => Sorry, characteristics couldn't be retrieved for #{@emitter.underscore.pluralize} (via #{url})"
          done
        end
      end
      
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
      
      def emission
        puts "  => #{emission_in_kilograms} kg CO2e"
      end
      
      def emission_in_kilograms
        impact(:timeframe => @timeframe).decisions.carbon.object.value
      end
      
      def lbs
        puts "  => #{emission_in_kilograms.kilograms.to :pounds} lbs CO2e"
      end
      alias :pounds :lbs
      
      def tons
        puts "  => #{emission_in_kilograms.kilograms.to :tons} lbs CO2e"
      end
      
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
      
      def url
        puts "  => #{impact(:timeframe => @timeframe).methodology}"
      end
      
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
      
      def help
        puts "  => #{@characteristics.keys.join ', '}"
      end
      
      prompt_with do |emitter|
        if emitter._timeframe
          "#{emitter._name}[#{emitter._timeframe}]*"
        else          
          "#{emitter._name}*"
        end
      end
      
      def _name
        @emitter
      end
      
      def _timeframe
        @timeframe
      end
      
      def inspect
        "#<Emitter[#{@emitter}]: #{@input.inspect}>"
      end
      
      def done
        $emitters[@emitter] ||= []
        $emitters[@emitter] << @input
        puts "  => Saved as #{@emitter} ##{$emitters[@emitter].length - 1}"
        quit
      end
      
      class << self
        def emitter_name
          @name
        end
      end
    end
  end
end
