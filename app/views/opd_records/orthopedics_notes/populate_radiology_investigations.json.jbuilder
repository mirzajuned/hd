json.set! "radiologydata" do
  json.set! "xrayinvestigations" do
    json.array!(@xrayinvestigations) do |xrayinvestigation|
      json.investigation_type "#{xrayinvestigation.investigation_type}"
      json.investigation_name "#{xrayinvestigation.investigation_name.to_s}"
      json.investigation_id "#{xrayinvestigation.investigation_id}"
      json.has_laterality "#{xrayinvestigation.has_laterality}"
      json.specialty_id "#{xrayinvestigation.specialty_id}"
      json.template_id "#{xrayinvestigation.template_id}"
      json.investigation_type_id "#{xrayinvestigation.investigation_type_id}"
    end
  end
  json.set! "ctmriinvestigations" do
    json.array!(@ctmriinvestigations) do |ctmriinvestigation|
      json.investigation_type "#{ctmriinvestigation.investigation_type}"
      json.investigation_name "#{ctmriinvestigation.investigation_name.to_s}"
      json.investigation_id "#{ctmriinvestigation.investigation_id}"
      json.has_laterality "#{ctmriinvestigation.has_laterality}"
      json.specialty_id "#{ctmriinvestigation.specialty_id}"
      json.template_id "#{ctmriinvestigation.template_id}"
      json.investigation_type_id "#{ctmriinvestigation.investigation_type_id}"
    end
  end
end
