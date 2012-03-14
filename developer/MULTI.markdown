Had this for a while

    def self.impacts(enumerable)
      queries = enumerable.map do |instance|
        [ Registry.instance[instance.class.name].emitter, instance.impact_params ]
      end
      multi queries
    end

Tested like this

    describe :impacts do
      it "works" do
        impacts = Carbon.impacts(MyNissanAltima.all(:order => :year))
        impacts.length.must_equal 5
        impacts.map do |impact|
          impact.decisions.carbon.object.value.round
        end.uniq.length.must_be :>, 3
        impacts.each_with_index do |impact, idx|
          impact.decisions.carbon.object.value.must_be :>, 0
          impact.characteristics.make.description.must_match %r{Nissan}i
          impact.characteristics.year.description.to_i.must_equal(2000+idx)
        end
      end
    end
