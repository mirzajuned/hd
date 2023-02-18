json.array!(@appointments.group(:appointmentdate)) do |appointmentgroup|
  json.set! Time.strptime("#{appointmentgroup.appointmentdate.to_s}", '%Y-%m-%d').strftime('%d/%m/%Y') do
    json.array!(@appointments.where(:appointmentdate => "#{appointmentgroup.appointmentdate.to_s}").limit(2)) do |appointment|
      json.patientid "#{appointment.patient.patientid}"
      json.patienthospitalid "#{appointment.patient.hospitalpatientid}"
      json.patientname "#{appointment.patient.fullname}"
      json.patientage "#{appointment.patient.age}"
      json.patientsex "#{appointment.patient.gender}"
      json.patientdob "#{appointment.patient.dob}"
      json.appointmenttime "#{Time.strptime("#{appointment.appointmenttime}", "%Y-%m-%d %H:%M:%S").strftime("%I:%M %p")}"
      json.appointmenttimesorting "#{Time.strptime("#{appointment.appointmenttime}", "%Y-%m-%d %H:%M:%S").strftime("%H:%M:%S")}"
    end
  end
end
