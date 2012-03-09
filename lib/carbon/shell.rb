require 'carbon'
require 'bombshell'
require 'conversions'
require 'brighter_planet_metadata'

module Carbon
  # @private
  class Shell < Bombshell::Environment
    class << self
      # @private
      def emitters
        ::BrighterPlanet.metadata.emitters
      end
    end

    include Bombshell::Shell
    
    before_launch do
      $emitters = {}
      emitters.map(&:underscore).each do |e|
        define_method e.to_sym do |*args|
          if args.any? and num = args.first and saved = $emitters[e.to_sym][num]
            emitter e.to_sym, saved
          else
            emitter e.to_sym
          end
        end
      end
    end
    
    prompt_with 'carbon-'

    # @private
    def help
      puts "  => #{self.class.emitters.join ', '}"
    end

    # @private
    def key(k)
      ::Carbon.key = k
      puts "  => Using key #{::Carbon.key}"
    end

    # @private
    def emitter(e, saved = {})
      Emitter.launch e, saved
    end
  end
end

if File.exist?(dotfile = File.join(ENV['HOME'], '.brighter_planet'))
  if (key = File.read(dotfile).strip).present?
    ::Carbon.key = key
  end
end

require 'carbon/shell/emitter'
