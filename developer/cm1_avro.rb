require 'active_support/core_ext'
require File.expand_path('../avro_helper', __FILE__)

module Cm1Avro
  class Impact
    def notes
      [
        "All emitters return carbon (@impact_response.decisions.carbon).",
        "Check emitter documentation to see what other impacts (energy, waste, etc.) are returned."
      ]
    end
    
    def dns_name
      'impact.brighterplanet.com'
    end
    
    def namespace
      dns_name.split('.').reverse.join('.')
    end

    def example
      {"compliance"=>[],
       "decisions"=>
        {"carbon"=>
          {"description"=>"78.7 kg",
           "object"=>{"value"=>78.67540811299375, "units"=>"kilograms"},
           "methodology"=>"from fuel use and greenhouse gas emission factor"},
         "ghg_emission_factor"=>
          {"description"=>"5.15214",
           "object"=>5.15214,
           "methodology"=>"from fuel and aviation multiplier"},
         "aviation_multiplier"=>
          {"description"=>"2.0", "object"=>2.0, "methodology"=>"default"},
         "energy"=>
          {"description"=>"574.6 MJ",
           "object"=>{"value"=>574.5759972448694, "units"=>"megajoules"},
           "methodology"=>"from fuel use and fuel"},
         "fuel_use"=>
          {"description"=>"15.270432890603466",
           "object"=>15.270432890603466,
           "methodology"=>
            "from fuel per segment, segments per trip, trips, freight_share, passengers, seat class multiplier, fuel, date, and timeframe"},
         "fuel_per_segment"=>
          {"description"=>"1480.9925950502234",
           "object"=>1480.9925950502234,
           "methodology"=>
            "from adjusted distance per segment and fuel use coefficients"},
         "seat_class_multiplier"=>
          {"description"=>"1.0", "object"=>1.0, "methodology"=>"default"},
         "distance_class"=>
          {"description"=>"short haul",
           "object"=>
            {"flight_distance_class"=>
              {"distance"=>1108.0,
               "distance_units"=>"kilometres",
               "max_distance"=>3700.0,
               "max_distance_units"=>"kilometres",
               "min_distance"=>0.0,
               "min_distance_units"=>"kilometres",
               "name"=>"short haul"}},
           "methodology"=>"from adjusted distance per segment"},
         "adjusted_distance_per_segment"=>
          {"description"=>"100.8961154095222",
           "object"=>100.8961154095222,
           "methodology"=>"from adjusted distance and segments per trip"},
         "adjusted_distance"=>
          {"description"=>"100.8961154095222",
           "object"=>100.8961154095222,
           "methodology"=>
            "from distance, route inefficiency factor, and dogleg factor"},
         "distance"=>
          {"description"=>"94.29543496217028",
           "object"=>94.29543496217028,
           "methodology"=>"from airports"},
         "route_inefficiency_factor"=>
          {"description"=>"1.07", "object"=>1.07, "methodology"=>"from country"},
         "dogleg_factor"=>
          {"description"=>"1.0",
           "object"=>1.0,
           "methodology"=>"from segments per trip"},
         "fuel_use_coefficients"=>
          {"description"=>
            "BrighterPlanet::Flight::ImpactModel::FuelUseEquation::Given",
           "object"=>{"m3"=>4.986e-08, "m2"=>8.255e-05, "m1"=>5.246, "b"=>950.8},
           "methodology"=>"from aircraft"},
         "fuel"=>
          {"description"=>"Jet Fuel",
           "object"=>
            {"fuel"=>
              {"biogenic_fraction"=>0.0,
               "carbon_content"=>18.672,
               "carbon_content_units"=>"grams_per_megajoule",
               "co2_biogenic_emission_factor"=>0.0,
               "co2_biogenic_emission_factor_units"=>"kilograms_per_litre",
               "co2_emission_factor"=>2.57607,
               "co2_emission_factor_units"=>"kilograms_per_litre",
               "density"=>0.8156,
               "density_units"=>"kilograms_per_litre",
               "energy_content"=>37.6267,
               "energy_content_units"=>"megajoules_per_litre",
               "name"=>"Jet Fuel",
               "oxidation_factor"=>1.0,
               "physical_units"=>nil}},
           "methodology"=>"default"},
         "passengers"=>
          {"description"=>"111",
           "object"=>111,
           "methodology"=>"from seats and load factor"},
         "seats"=>
          {"description"=>"143.096",
           "object"=>143.096,
           "methodology"=>"from aircraft"},
         "load_factor"=>
          {"description"=>"0.7734122348583675",
           "object"=>0.7734122348583675,
           "methodology"=>"default"},
         "freight_share"=>
          {"description"=>"0.0665336701213722",
           "object"=>0.0665336701213722,
           "methodology"=>"default"},
         "country"=>
          {"description"=>"US",
           "object"=>
            {"country"=>
              {"automobile_city_speed"=>32.0259,
               "automobile_city_speed_units"=>"kilometres_per_hour",
               "automobile_fuel_efficiency"=>9.2669,
               "automobile_fuel_efficiency_units"=>"kilometres_per_litre",
               "automobile_highway_speed"=>91.8935,
               "automobile_highway_speed_units"=>"kilometres_per_hour",
               "automobile_trip_distance"=>16.3348,
               "automobile_trip_distance_units"=>"kilometres",
               "automobile_urbanity"=>0.43,
               "cooling_degree_days"=>882.0,
               "cooling_degree_days_units"=>"degrees_celsius",
               "electricity_emission_factor"=>0.589455,
               "electricity_emission_factor_units"=>
                "kilograms_co2e_per_kilowatt_hour",
               "electricity_loss_factor"=>0.0615633,
               "flight_route_inefficiency_factor"=>1.07,
               "heating_degree_days"=>2159.0,
               "heating_degree_days_units"=>"degrees_celsius",
               "iso_3166_alpha_3_code"=>"USA",
               "iso_3166_code"=>"US",
               "iso_3166_numeric_code"=>840,
               "lodging_district_heat_intensity"=>1.73952,
               "lodging_district_heat_intensity_units"=>"megajoules_per_room_night",
               "lodging_electricity_intensity"=>33.3145,
               "lodging_electricity_intensity_units"=>
                "kilowatt_hours_per_room_night",
               "lodging_fuel_oil_intensity"=>0.411674,
               "lodging_fuel_oil_intensity_units"=>"gallons_per_room_night",
               "lodging_natural_gas_intensity"=>1.96714,
               "lodging_natural_gas_intensity_units"=>"cubic_metres_per_room_night",
               "lodging_occupancy_rate"=>0.601,
               "name"=>"United States",
               "rail_passengers"=>4467000000.0,
               "rail_speed"=>32.4972,
               "rail_speed_units"=>"kilometres_per_hour",
               "rail_trip_co2_emission_factor"=>0.0957617,
               "rail_trip_co2_emission_factor_units"=>
                "kilograms_per_passenger_kilometre",
               "rail_trip_diesel_intensity"=>0.0194247,
               "rail_trip_diesel_intensity_units"=>"litres_per_passenger_kilometre",
               "rail_trip_distance"=>12.9952,
               "rail_trip_distance_units"=>"kilometres",
               "rail_trip_electricity_intensity"=>0.140512,
               "rail_trip_electricity_intensity_units"=>
                "kilowatt_hours_per_passenger_kilometre"}},
           "methodology"=>"from origin airport and destination airport"},
         "date"=>
          {"description"=>"2012-01-01",
           "object"=>"2012-01-01",
           "methodology"=>"from timeframe"}},
       "emitter"=>"Flight",
       "equivalents"=>
        {"cars_off_the_road_for_a_year"=>0.014318924276564863,
         "cars_off_the_road_for_a_month"=>0.17166974050255235,
         "cars_off_the_road_for_a_week"=>0.743875983708356,
         "cars_off_the_road_for_a_day"=>5.221372134826943,
         "cars_to_priuses_for_a_year"=>0.028637848553129727,
         "cars_to_priuses_for_a_month"=>0.3433394810051047,
         "cars_to_priuses_for_a_week"=>1.487751967416712,
         "cars_to_priuses_for_a_day"=>10.442744269653886,
         "one_way_domestic_flight"=>0.25569507636722966,
         "round_trip_domestic_flight"=>0.12784753818361483,
         "one_way_cross_country_flight"=>0.08984731606503886,
         "round_trip_cross_country_flight"=>0.04492365803251943,
         "vegan_meals_instead_of_non_vegan_ones"=>63.309078128220605,
         "days_of_veganism"=>21.1030260427402,
         "weeks_of_veganism"=>3.014684288073694,
         "months_of_veganism"=>0.7034368239382771,
         "years_of_veganism"=>0.057826424963050405,
         "barrels_of_petroleum"=>0.18299899927082347,
         "canisters_of_bbq_propane"=>3.278168229844111,
         "railroad_cars_full_of_coal"=>0.0003933770405649688,
         "homes_energy_in_a_year"=>0.007631514586960394,
         "homes_energy_in_a_month"=>0.09118479800295977,
         "homes_energy_in_a_week"=>0.39502922413534164,
         "homes_energy_in_a_day"=>2.7730721097586906,
         "homes_electricity_in_a_year"=>0.011565284992610081,
         "homes_electricity_in_a_month"=>0.138390042870756,
         "homes_electricity_in_a_week"=>0.5996639606372384,
         "homes_electricity_in_a_day"=>4.209055658637053,
         "homes_with_lowered_thermostat_2_degrees_for_a_winter"=>0.4129672171851042,
         "homes_with_raised_thermostat_3_degrees_for_a_summer"=>0.18567396314666526,
         "replaced_refrigerators"=>0.07922613596978471,
         "loads_of_cold_laundry"=>36.077552495110645,
         "lightbulbs_for_a_year"=>0.14523480337658645,
         "lightbulbs_for_a_month"=>1.7674430432584045,
         "lightbulbs_for_a_week"=>7.574710942302812,
         "lightbulbs_for_a_day"=>53.023212622344026,
         "lightbulbs_for_an_evening"=>318.1393544094722,
         "lightbulbs_to_CFLs_for_a_day"=>902.523055958413,
         "lightbulbs_to_CFLs_for_a_week"=>128.93184265822813,
         "lightbulbs_to_CFLs_for_a_month"=>30.08413858047089,
         "lightbulbs_to_CFLs_for_a_year"=>2.4726894015832803,
         "days_with_lightbulbs_to_CFLs"=>20.05609238698059,
         "weeks_with_lightbulbs_to_CFLs"=>2.8651223372508934,
         "months_with_lightbulbs_to_CFLs"=>0.6685049427361078,
         "years_with_lightbulbs_to_CFLs"=>0.05491543486286964,
         "recycled_kgs_of_trash"=>54.258888582166705,
         "recycled_bags_of_trash"=>30.064627079258866},
       "methodology"=>
        "http://impact.brighterplanet.com/flights?aircraft[icao_code]=B737&airline[iata_code]=UA&destination_airport[iata_code]=ORD&origin_airport[iata_code]=MSN&segments_per_trip=1&trips=1",
       "scope"=>
        "The flight greenhouse gas emission is the anthropogenic greenhouse gas emissions attributed to a single passenger on this flight. It includes CO2 emissions from combustion of non-biogenic fuel and extra forcing effects of high-altitude fuel combustion.",
       "timeframe"=>{"startDate"=>"2012-01-01", "endDate"=>"2013-01-01"},
       "characteristics"=>
        {"segments_per_trip"=>{"description"=>"1", "object"=>1},
         "trips"=>{"description"=>"1", "object"=>1},
         "origin_airport"=>
          {"description"=>"MSN",
           "object"=>
            {"airport"=>
              {"city"=>"Madison",
               "country_iso_3166_code"=>"US",
               "country_name"=>"United States",
               "iata_code"=>"MSN",
               "latitude"=>43.1399,
               "longitude"=>-89.3375,
               "name"=>"Dane County Regional Truax Field"}}},
         "destination_airport"=>
          {"description"=>"ORD",
           "object"=>
            {"airport"=>
              {"city"=>"Chicago",
               "country_iso_3166_code"=>"US",
               "country_name"=>"United States",
               "iata_code"=>"ORD",
               "latitude"=>41.9786,
               "longitude"=>-87.9048,
               "name"=>"Chicago Ohare International"}}},
         "airline"=>
          {"description"=>"United Airlines",
           "object"=>
            {"airline"=>
              {"bts_code"=>"UA",
               "iata_code"=>"UA",
               "icao_code"=>"UAL",
               "name"=>"United Airlines"}}},
         "aircraft"=>
          {"description"=>"B737",
           "object"=>
            {"aircraft"=>
              {"aircraft_type"=>"Landplane",
               "b"=>950.8,
               "b_units"=>"kilograms",
               "class_code"=>"Medium 2 engine Jet",
               "description"=>"boeing 737-700",
               "engine_type"=>"Jet",
               "engines"=>2,
               "fuel_use_specificity"=>"aircraft",
               "icao_code"=>"B737",
               "m1"=>5.246,
               "m1_units"=>"kilograms_per_nautical_mile",
               "m2"=>8.255e-05,
               "m2_units"=>"kilograms_per_square_nautical_mile",
               "m3"=>4.986e-08,
               "m3_units"=>"kilograms_per_cubic_nautical_mile",
               "manufacturer_name"=>"BOEING",
               "model_name"=>"737-700",
               "passengers"=>322259000.0,
               "seats"=>143.096,
               "seats_specificity"=>"aircraft",
               "weight_class"=>"Large"}}}},
       "errors"=>[]}
    end

    def avro_response_schema
      timeframe = {
        :type => 'record',
        :name => 'Timeframe',
        :fields => [
          { :name => 'startDate', :type => 'string' },
          { :name => 'endDate', :type => 'string' },
        ]
      }
      
      decision_object = {
        :namespace => namespace,
        :type => 'record',
        :name => 'DecisionObject',
        :fields => [
          { :name => 'value', :type => AvroHelper::OPTIONAL_SCALAR },
          { :name => 'units', :type => AvroHelper::OPTIONAL_STRING },
        ]
      }

      characteristic_object = {
        :namespace => namespace,
        :type => 'record',
        :name => 'CharacteristicObject',
        :fields => [
          { :name => 'value', :type => AvroHelper::OPTIONAL_SCALAR },
          { :name => 'units', :type => AvroHelper::OPTIONAL_STRING },
        ]
      }


# { :type => 'map', :values => AvroHelper::OPTIONAL_SCALAR }

      decision = {
        :namespace => namespace,
        :type => 'record',
        :name => 'Decision',
        :fields => [
          { :name => 'description', :type => 'string' },
          { :name => 'object', :type => (AvroHelper::SCALAR+[decision_object]) }, # should really be optional map
          { :name => 'methodology', :type => 'string' }
        ]
      }
      
      characteristic = {
        :namespace => namespace,
        :type => 'record',
        :name => 'Characteristic',
        :fields => [
          { :name => 'description', :type => 'string' },
          { :name => 'object', :type => (AvroHelper::SCALAR+[characteristic_object]) }, # should really be optional map
        ]
      }
      
      {
        :namespace => namespace,
        :type => 'record',
        :name => 'Response',
        :fields => [
          { :name => 'emitter', :type => 'string' },
          { :name => 'characteristics', :type => { :type => 'map', :values => characteristic } },
          { :name => 'decisions', :type => { :type => 'map', :values => decision } },
          { :name => 'errors', :type => { :type => 'array', :items => 'string' } },
          { :name => 'timeframe', :type => timeframe },
          { :name => 'methodology', :type => 'string' },
          # { :name => 'audit_id', :type => 'string' }, # paid extra
          { :name => 'scope', :type => 'string' },
          { :name => 'compliance', :type => { :type => 'array', :items => 'string' } },
          { :name => 'equivalents', :type => { :type => 'map', :values => 'float' } },
          { :name => 'certification', :type => AvroHelper::OPTIONAL_STRING },
        ]
      }
    end
  end
  
  class Carbon
    def notes
      [
        "DEPRECATED. Use impact.brighterplanet.com, which will give you @impact_response.decisions.carbon",
        "Characteristics are mixed into the root of the response. For example: @carbon_response.origin_airport",
        "Used by Brighter Planet carbon library versions < 1.2"
      ]
    end
    
    def dns_name
      'carbon.brighterplanet.com'
    end
    
    def namespace
      dns_name.split('.').reverse.join('.')
    end
    
    def avro_response_schema
      quorum = {
        :namespace => namespace,
        :type => 'record',
        :name => 'Quorum',
        :fields => [
          { :name => 'name', :type => 'string' },
          { :name => 'requirements', :type => { :type => 'array', :items => 'string' } },
          { :name => 'appreciates', :type => { :type => 'array', :items => 'string' } },
          { :name => 'complies', :type => { :type => 'array', :items => 'string' } }
        ]
      }
      committee_stub = {
        :namespace => namespace,
        :type => 'record',
        :name => 'Committee',
        :fields => [
          { :name => 'name', :type => 'string' }
        ]
      }
      report = {
        :namespace => namespace,
        :type => 'record',
        :name => 'Report',
        :fields => [
          { :name => 'committee', :type => committee_stub },
          { :name => 'conclusion', :type => AvroHelper::SCALAR },
          { :name => 'quorum', :type => quorum }
        ]
      }
      {
        :namespace => namespace,
        :type => 'record',
        :name => 'Response',
        :fields => [
          # { :name => '*', :type => OPTIONAL_SCALAR }, # the characteristics mixed in with the root
          { :name => 'emission', :type => 'float' },
          { :name => 'emitter', :type => 'string' },
          { :name => 'timeframe', :type => 'string' },
          { :name => 'emission_units', :type => 'string' },
          { :name => 'methodology', :type => 'string' },
          { :name => 'execution_id', :type => 'string' },
          { :name => 'scope', :type => 'string' },
          { :name => 'complies', :type => { :type => 'array', :items => 'string' } },
          { :name => 'errors', :type => { :type => 'array', :items => 'string' } },
          { :name => 'equivalents', :type => { :type => 'map', :values => 'float' } },
          { :name => 'reports', :type => { :type => 'array', :items => report } },
          { :name => 'certification', :type => AvroHelper::OPTIONAL_STRING },
        ]
      }
    end
  
    def example
      ActiveSupport::JSON.decode <<-EOS
      {
          "emission": 619.3139931256935,
          "emitter": "Flight",
          "timeframe": "2011-01-01/2012-01-01",
          "emission_units": "kilograms",
          "methodology": "http://carbon.brighterplanet.com/flights.html?destination_airport[iata_code]=SFO&origin_airport[iata_code]=JAC&timeframe=2011-01-01%2F2012-01-01",
          "execution_id": "ae70601773dab95c67665d6bfbba71006c03bd9e",
          "scope": "The flight emission estimate is the anthropogenic emissions per passenger from aircraft fuel combustion and radiative forcing. It includes CO2 emissions from combustion of non-biogenic fuel and extra forcing effects of high-altitude combustion.",
          "complies": [],
          "errors": [],
          "equivalents": {
              "cars_off_the_road_for_a_year": 0.11271514674887623,
              "cars_off_the_road_for_a_month": 1.3513431330002632,
              "cars_off_the_road_for_a_week": 5.855613805003432,
              "cars_off_the_road_for_a_day": 41.101392467779775,
              "cars_to_priuses_for_a_year": 0.22543029349775245,
              "cars_to_priuses_for_a_month": 2.7026862660005264,
              "cars_to_priuses_for_a_week": 11.711227610006864,
              "cars_to_priuses_for_a_day": 82.20278493555955,
              "one_way_domestic_flight": 2.012770477658504,
              "round_trip_domestic_flight": 1.006385238829252,
              "one_way_cross_country_flight": 0.707256580149542,
              "round_trip_cross_country_flight": 0.353628290074771,
              "vegan_meals_instead_of_non_vegan_ones": 498.35391918633496,
              "days_of_veganism": 166.11797306211164,
              "weeks_of_veganism": 23.730873588590324,
              "months_of_veganism": 5.537286412536825,
              "years_of_veganism": 0.4551957849473847,
              "barrels_of_petroleum": 1.440524348010363,
              "canisters_of_bbq_propane": 25.804956151568273,
              "railroad_cars_full_of_coal": 0.0030965699656284678,
              "homes_energy_in_a_year": 0.06007345733319227,
              "homes_energy_in_a_month": 0.7177849180326789,
              "homes_energy_in_a_week": 3.1095755594841075,
              "homes_energy_in_a_day": 21.82896031570132,
              "homes_electricity_in_a_year": 0.09103915698947694,
              "homes_electricity_in_a_month": 1.0893733139080948,
              "homes_electricity_in_a_week": 4.720411255604036,
              "homes_electricity_in_a_day": 33.132679318231474,
              "homes_with_lowered_thermostat_2_degrees_for_a_winter": 3.2507791499167653,
              "homes_with_raised_thermostat_3_degrees_for_a_summer": 1.4615810237766367,
              "replaced_refrigerators": 0.6236491910775734,
              "loads_of_cold_laundry": 283.9938633157043,
              "lightbulbs_for_a_year": 1.1432536313100303,
              "lightbulbs_for_a_month": 13.912888855568704,
              "lightbulbs_for_a_week": 59.626312630155525,
              "lightbulbs_for_a_day": 417.386046353068,
              "lightbulbs_for_an_evening": 2504.3168974324008,
              "lightbulbs_to_CFLs_for_a_day": 7104.445608605558,
              "lightbulbs_to_CFLs_for_a_week": 1014.9206242825103,
              "lightbulbs_to_CFLs_for_a_month": 236.81514263338204,
              "lightbulbs_to_CFLs_for_a_year": 19.46441948994742,
              "days_with_lightbulbs_to_CFLs": 157.87676175558803,
              "weeks_with_lightbulbs_to_CFLs": 22.55355768765838,
              "months_with_lightbulbs_to_CFLs": 5.262310999589017,
              "years_with_lightbulbs_to_CFLs": 0.4322811672017341,
              "recycled_kgs_of_trash": 427.1129919291002,
              "recycled_bags_of_trash": 236.6615527630869
          },
          "origin_airport": {
              "airport": {
                  "city": "Jacksn Hole",
                  "country_iso_3166_code": "US",
                  "country_name": "United States",
                  "iata_code": "JAC",
                  "latitude": 43.6073,
                  "longitude": -110.738,
                  "name": "Jackson Hole"
              }
          },
          "destination_airport": {
              "airport": {
                  "city": "San Francisco",
                  "country_iso_3166_code": "US",
                  "country_name": "United States",
                  "iata_code": "SFO",
                  "latitude": 37.619,
                  "longitude": -122.375,
                  "name": "San Francisco International"
              }
          },
          "date": "2011-01-01",
          "segments_per_trip": 1.68,
          "country": {
              "country": {
                  "automobile_city_speed": 32.0259,
                  "automobile_city_speed_units": "kilometres_per_hour",
                  "automobile_fuel_efficiency": 9.2669,
                  "automobile_fuel_efficiency_units": "kilometres_per_litre",
                  "automobile_highway_speed": 91.8935,
                  "automobile_highway_speed_units": "kilometres_per_hour",
                  "automobile_trip_distance": 16.3348,
                  "automobile_trip_distance_units": "kilometres",
                  "automobile_urbanity": 0.43,
                  "flight_route_inefficiency_factor": 1.07,
                  "iso_3166_code": "US",
                  "name": "UNITED STATES"
              }
          },
          "trips": 1.7,
          "freight_share": 0.070644984859677,
          "load_factor": 0.76992050796823,
          "seats": 171.0530182753,
          "passengers": 132,
          "fuel": {
              "fuel": {
                  "biogenic_fraction": 0,
                  "carbon_content": 18.672,
                  "carbon_content_units": "grams_per_megajoule",
                  "co2_biogenic_emission_factor": 0,
                  "co2_biogenic_emission_factor_units": "kilograms_per_litre",
                  "co2_emission_factor": 2.57607,
                  "co2_emission_factor_units": "kilograms_per_litre",
                  "density": 0.808,
                  "density_units": "kilograms_per_litre",
                  "energy_content": 37.6267,
                  "energy_content_units": "megajoules_per_litre",
                  "name": "Jet Fuel",
                  "oxidation_factor": 1
              }
          },
          "fuel_use_coefficients": [
              1.0886676283223e-7,
              -0.00017055946628547,
              6.9195725633675,
              1572.3367918346
          ],
          "dogleg_factor": 1.1638548181950328,
          "route_inefficiency_factor": 1.07,
          "distance": 640.3861758339607,
          "adjusted_distance": 797.4886937873359,
          "adjusted_distance_per_segment": 474.69565106389047,
          "seat_class_multiplier": 1,
          "fuel_per_segment": 4830.2396558575165,
          "fuel_use": 13795.164457129067,
          "aviation_multiplier": 2,
          "emission_factor": 3.1882054455445545,
          "reports": [
              {
                  "committee": {
                      "name": "emission"
                  },
                  "conclusion": "619.3139931256935",
                  "quorum": {
                      "name": "from fuel use, emission factor, freight share, passengers, multipliers, and date",
                      "requirements": [
                          "fuel_use",
                          "emission_factor",
                          "freight_share",
                          "passengers",
                          "seat_class_multiplier",
                          "aviation_multiplier",
                          "date"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "emission_factor"
                  },
                  "conclusion": "3.1882054455445545",
                  "quorum": {
                      "name": "from fuel",
                      "requirements": [
                          "fuel"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "aviation_multiplier"
                  },
                  "conclusion": "2.0",
                  "quorum": {
                      "name": "default",
                      "requirements": [],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "fuel_use"
                  },
                  "conclusion": "13795.164457129067",
                  "quorum": {
                      "name": "from fuel per segment and segments per trip and trips",
                      "requirements": [
                          "fuel_per_segment",
                          "segments_per_trip",
                          "trips"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "fuel_per_segment"
                  },
                  "conclusion": "4830.2396558575165",
                  "quorum": {
                      "name": "from adjusted distance per segment and fuel use coefficients",
                      "requirements": [
                          "adjusted_distance_per_segment",
                          "fuel_use_coefficients"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "seat_class_multiplier"
                  },
                  "conclusion": "1.0",
                  "quorum": {
                      "name": "from adjusted distance per segment",
                      "requirements": [
                          "adjusted_distance_per_segment"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "adjusted_distance_per_segment"
                  },
                  "conclusion": "474.69565106389047",
                  "quorum": {
                      "name": "from adjusted distance and segments per trip",
                      "requirements": [
                          "adjusted_distance",
                          "segments_per_trip"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "adjusted_distance"
                  },
                  "conclusion": "797.4886937873359",
                  "quorum": {
                      "name": "from distance, route inefficiency factor, and dogleg factor",
                      "requirements": [
                          "distance",
                          "route_inefficiency_factor",
                          "dogleg_factor"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "distance"
                  },
                  "conclusion": "640.3861758339607",
                  "quorum": {
                      "name": "from airports",
                      "requirements": [
                          "origin_airport",
                          "destination_airport"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "route_inefficiency_factor"
                  },
                  "conclusion": "1.07",
                  "quorum": {
                      "name": "from country",
                      "requirements": [
                          "country"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "dogleg_factor"
                  },
                  "conclusion": "1.1638548181950328",
                  "quorum": {
                      "name": "from segments per trip",
                      "requirements": [
                          "segments_per_trip"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "fuel_use_coefficients"
                  },
                  "conclusion": "#<struct BrighterPlanet::Flight::CarbonModel::FuelUseEquation m3=1.0886676283223e-07, m2=-0.00017055946628547, m1=6.9195725633675, b=1572.3367918346>",
                  "quorum": {
                      "name": "default",
                      "requirements": [],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "fuel"
                  },
                  "conclusion": "Jet Fuel",
                  "quorum": {
                      "name": "default",
                      "requirements": [],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "passengers"
                  },
                  "conclusion": "132",
                  "quorum": {
                      "name": "from seats and load factor",
                      "requirements": [
                          "seats",
                          "load_factor"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "seats"
                  },
                  "conclusion": "171.0530182753",
                  "quorum": {
                      "name": "default",
                      "requirements": [],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "load_factor"
                  },
                  "conclusion": "0.76992050796823",
                  "quorum": {
                      "name": "default",
                      "requirements": [],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "freight_share"
                  },
                  "conclusion": "0.070644984859677",
                  "quorum": {
                      "name": "default",
                      "requirements": [],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "trips"
                  },
                  "conclusion": "1.7",
                  "quorum": {
                      "name": "default",
                      "requirements": [],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "country"
                  },
                  "conclusion": "#<Country:0xb035ac4>",
                  "quorum": {
                      "name": "from origin airport and destination airport",
                      "requirements": [
                          "origin_airport",
                          "destination_airport"
                      ],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "segments_per_trip"
                  },
                  "conclusion": "1.68",
                  "quorum": {
                      "name": "default",
                      "requirements": [],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              },
              {
                  "committee": {
                      "name": "date"
                  },
                  "conclusion": "2011-01-01",
                  "quorum": {
                      "name": "from timeframe",
                      "requirements": [],
                      "appreciates": [],
                      "complies": [
                          "ghg_protocol_scope_3",
                          "iso",
                          "tcr"
                      ]
                  }
              }
          ]
      }
EOS
    end
  end
  
end
