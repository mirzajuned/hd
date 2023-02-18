class Facilitydata::Read

  def self.get_facility_attributes(facility_id, query_array)
    attributes = Facility.find_by(id: facility_id)&.attributes.slice(*query_array) # * or asterisk is required.
    return attributes
  end

end
