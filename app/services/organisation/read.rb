class Organisation::Read

  def self.get_attributes(organisation_id, query_array)
    attributes = Organisation.find_by(id: organisation_id)&.attributes.slice(*query_array) # * or asterisk is required.
    return attributes
  end

end
