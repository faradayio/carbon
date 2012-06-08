class MyNissan
  def name
    'Nissan'
  end
  def to_s
    raise "Not fair!"
  end
  alias :inspect :to_s
end

class MyNissanAltima
  class << self
    def all(options)
      raise unless options == { :order => :year }
      [ new(2000), new(2001), new(2002), new(2003), new(2004) ]
    end
  end
  def initialize(model_year)
    @model_year = model_year
  end
  def       make; MyNissan.new end
  def      model; 'Altima'     end
  def model_year; @model_year  end # what BP knows as "year"
  def  fuel_type; 'R'          end # what BP knows as "automobile_fuel" and keys on "code"
  def   nil_make; nil          end
  def  nil_model; nil          end
  include Carbon
  emit_as 'Automobile' do
    provide(:make) { |my_nissan_altima| my_nissan_altima.make.try(:name) }
    provide :model
    provide :model_year, :as => :year
    provide :fuel_type, :as => :automobile_fuel, :key => :code
    provide(:nil_make) { |my_nissan_altima| my_nissan_altima.nil_make.try(:blam!) }
    provide :nil_model
  end
end
