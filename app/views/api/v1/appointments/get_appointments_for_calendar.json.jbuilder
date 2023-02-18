json.array!(@appointments.group_by(&:appointmentdate)) do |appointmentgroup|
  json.set! Time.strptime("#{appointmentgroup.first.to_s}", '%Y-%m-%d').strftime('%Y-%m-%d') do
    json.array!(@appointments.where(:appointmentdate => "#{appointmentgroup.first.to_s}")) do |appointment|
      json.id appointment.id
      json.display_id appointment.display_id
      json.patient_id appointment.patient_id
      json.start_time appointment.start_time.strftime('%H:%M')
      json.appointment_type_id appointment.appointment_type_id
      json.facility_id appointment.facility_id
      json.user_id appointment.user_id
    end
  end
end
