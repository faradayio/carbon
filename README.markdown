# Carbon

Carbon is a Ruby API client and command-line console for the [Brighter Planet impact estimate web service](http://impact.brighterplanet.com), which is located at http://impact.brighterplanet.com. By querying the web service, it can estimate the carbon emissions, energy usage, and other environmental impacts of many real-life objects, such as cars and houses, based on particular characteristics that they may have.

Full documentation: [RDoc](http://rdoc.info/projects/brighterplanet/carbon) 

## Quick start 1: experimenting with the console

<b>You'll need a Brighter Planet API key. See the "API keys" section below for details.</b>

First get the gem:

    $ gem install carbon

Then start the console:

    $ carbon
    carbon->

Provide your key:

    carbon-> key '123ABC'
      => Using key 123ABC
      
Start a flight calculation:

    carbon-> flight
      => 1210.66889895298 kg CO2e
    flight*>

Start providing characteristics:

    flight*> origin_airport 'jfk'
      => 1593.46008200024 kg CO2e
    flight*> destination_airport 'lax'
      => 1766.55536727522 kg CO2e

Review what you've entered:

    flight*> characteristics
      => origin_airport: jfk
         destination_airport: lax

See how the calculation's being made:

    flight*> methodology
      => emission: from fuel and passengers with coefficients
         [ ... ]
         cohort: from t100
         
See intermediate calculations:

    flight*> reports
      => emission: 1766.55536727522
         [ ... ]
         cohort: {"members"=>262}

Generate a methodology URL:

    flight*> url
      => http://impact.brighterplanet.com/flights.json?origin_airport=jfk&destination_airport=lax&key=123ABC

And when you're done:

    flight*> done
      => Saved as flight #0
    carbon->

You can recall this flight anytime during this same session:

    carbon-> flight 0
      => 1766.55536727522 kg CO2e
    flight*> characteristics
      => origin_airport: jfk
         destination_airport: lax
         
For more, see the "Console" section below.

## Quick start 2: using the library in your application

<b>You'll need a Brighter Planet API key. See the "API keys" section below for details.</b>

Carbon works by extending any Ruby class to be an emission source. You `include Carbon` and then use the `emit_as` DSL...

    # see Carbon::ClassMethods#emit_as for more details
    class MyFlight
      def airline
        # ... => MyAirline(:name, :icao_code, ...)
      end
      def aircraft
        # ... => MyAircraft(:name, :icao_code, ...)
      end
      def origin
        # ... => String
      end
      def destination
        # ... => String
      end
      def segments_per_trip
        # ... => Integer
      end
      def trips
        # ... => Integer
      end
      include Carbon
      emit_as 'Flight' do
        provide :segments_per_trip
        provide :trips
        provide :origin, :as => :origin_airport, :key => :iata_code
        provide :destination, :as => :destination_airport, :key => :iata_code
        provide(:airline, :key => :iata_code) { |f| f.airline.try(:iata_code) }
        provide(:aircraft, :key => :icao_code) { { |f| f.aircraft.try(:icao_code) }
      end
    end

See [RDoc on `Carbon::ClassMethods#emit_as`](http://rdoc.info/github/brighterplanet/carbon/Carbon/ClassMethods#emit_as-instance_method) for all the details.

The final URL will be something like

    http://impact.brighterplanet.com/flights.json?segments_per_trip=1&trips=1&origin_airport[iata_code]=MSN&destination_airport[iata_code]=ORD&airline[iata_code]=UA&aircraft[icao_code]=B737

When you want to calculate impacts, simply call `MyFlight#impact`.

    ?> my_flight = MyFlight.new([...])
    => #<MyFlight [...]>
    ?> my_impact = my_flight.impact(:timeframe => Timeframe.new(:year => 2009))
    => #<Hashie::Mash [...]>
    ?> my_impact.decisions.carbon.object.value
    => 1014.92
    ?> my_impact.decisions.carbon.object.units
    => "kilograms"
    ?> my_impact.methodology
    => "http://impact.brighterplanet.com/flights?[...]"

See [RDoc on `Carbon#impact`](http://rdoc.info/github/brighterplanet/carbon/Carbon#impact-instance_method) for all the details.

## API keys

You should get an API key from http://keys.brighterplanet.com and set it globally:

    Carbon.key = '12903019230128310293'

Now all of your queries will use that key.

## Gotcha: timeframes and 0.0kg results

You submit this query about a flight in 2009, but the result is 0.0 kilograms. Why?

  $ carbon 
  carbon-> flight
  [...]
  flight*> date '2009-05-03'
    => 0.0 kg CO2e
  flight*> url
    => http://impact.brighterplanet.com/flights?date=2009-05-03

It's telling you that a flight in 2009 did not result in any 2011 emissions (the default timeframe is the current year).

  flight*> timeframe '2009'
    => 847.542137647608 kg CO2e
  flight*> url
    => http://impact.brighterplanet.com/flights?date=2009-05-03&timeframe=2009-01-01/2010-01-01

So, 850 kilograms emitted in 2009.

## Console

This library includes a special console for performing calculations interactively. Quick Start #1 provides an example session. Here is a command reference:

### Shell mode

`help`
:  Displays a list of emitter types.

`key` _yourkey_
:  Set the [developer key](http://keys.brighterplanet.com) that should be used for this session. Alternatively, put this key in `~/.brighter_planet` and it will be auto-selected on console startup.

_emitter_
:  (e.g. `flight`) Enters emitter mode using this emitter type.

_emitter num_
:  (e.g. `flight 0`) Recalls a previous emitter from this session.

`exit`
:  Quits.
  
### Emitter mode

In Emitter mode, the prompt displays the emitter type in use. If a timeframe has been set, the timeframe is also included in the prompt.

`help`
:  Displays a list of characteristics for this emitter type.

_characteristic value_
:  (e.g. `origin_airport 'lax'`)
:  Provide a characteristic. Remember, this is Ruby we're dealing with, so strings must be quoted.

`timeframe`
:  Display the current timeframe in effect on the emission estimate.

`timeframe` _timeframe_
:  (e.g. `timeframe '2009-01-01/2010-01-01'` or just `timeframe '2009'`) Set a timeframe on the emission estimate.

`emission`
:  Displays the current emission in kilograms CO2e for this emitter.

`lbs`, `pounds`, or `tons`
:  Display the emission using different units.

`characteristics`
:  Lists the characteristics you have provided so far.

`methodology`
:  Summarizes how the calculation is being made.

`reports`
:  Displays intermediate calculations that were made in pursuit of the emission estimate.

`url`
:  Generates a methodology URL suitable for pasting into your browser for further inspection.

`done`
:  Saves this emitter and returns to shell mode.

## Copyright

Copyright (c) 2012 Brighter Planet.
