json.set! "registerpatientappointmentresult" do
  json.hgstatus "5000"
  json.hgstatustext "Patient Registered and Appointment Created"
  json.patientid @patient.patientid
  json.appointmentid @appointment.appointmentid
end
