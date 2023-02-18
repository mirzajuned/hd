json.set! @radiologycode.to_s do
  @radiology.group(:position).each do |radiology|
    json.set! "#{radiology.position.to_s}###{radiology.radiologydisplayrule}###{radiology.preselected}" do
      json.array!(@radiology.where(:position => "#{radiology.position.to_s}").order(radiologyinternalcode: :asc)) do |radiology_attr|
        json.set! "#{radiology_attr.displayradiologylabel}", "#{radiology_attr.displayradiologylabel}###{radiology_attr.radiologyinternalcode}"
      end
    end
  end
end
