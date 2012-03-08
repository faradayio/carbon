In your gemfile:

    gem 'brighter_planet_api', :git => 'git://gist.github.com/1960760.git'

Tested on MRI 1.8 and MRI 1.9. Won't work right on JRuby until https://github.com/eventmachine/eventmachine/issues/155 is fixed.

    class MyNissanAltima < ActiveRecord::Base
      # model_year: int
      # make: string
      # model: string
      # fuel_type: string

      include BrighterPlanetApi

      emit_as 'Automobile' do
        provide :make
        provide :model
        provide :model_year, :as => :year
        provide :fuel_type, :as => :automobile_fuel, :key => :code
      end
    end

Then you can call

    MyNissanAltima.first.impact #=> one estimate

or

    BrighterPlanetApi.impacts(MyNissanAltima.all, :where => { :year => 2006}) #=> many estimates
