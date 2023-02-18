class Appointment::Read

  def self.get_appointment_attributes(appointment_id, query_array)
    attributes = Appointment.find_by(id: appointment_id)&.attributes.slice(*query_array) # * or asterisk is required.
    return attributes
  end

end
