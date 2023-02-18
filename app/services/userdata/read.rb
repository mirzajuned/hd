class Userdata::Read

  def self.get_user_attributes(user_id, query_array)
    attributes = User.find_by(id: user_id)&.attributes.slice(*query_array) # * or asterisk is required.
    return attributes
  end

end
