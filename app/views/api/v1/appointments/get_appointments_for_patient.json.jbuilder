json.array!(@appointments) do |appointment|
  json.appointmentdate "#{Time.strptime("#{appointment.appointmentdate}", "%Y-%m-%d").strftime("%d/%m/%Y")}"
  json.appointmenttime "#{Time.strptime("#{appointment.appointmenttime}", "%Y-%m-%d %H:%M:%S").strftime("%I:%M %p")}"
  json.appointmenttimesorting "#{Time.strptime("#{appointment.appointmenttime}", "%Y-%m-%d %H:%M:%S").strftime("%H:%M:%S")}"
  json.hgstatus "5000"
  json.hgstatustext "Appointment Created"
  json.patientid @patient.patientid
  json.appointmentid @appointment.appointmentid
end
