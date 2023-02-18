json.message @message
json.appointment_id @appointment.id
json.patient_id @appointment.patient_id

json.set! "patient_dilation_list" do
  json.array!(@patient_dilation_list) do |patient_dilation|
    json.id patient_dilation.id
    json.user_id patient_dilation.user_id
    json.appointment_id patient_dilation.appointment_id
    json.patient_id patient_dilation.patient_id
    json.start_time patient_dilation.try(:start_time)
    json.end_time patient_dilation.try(:end_time)
    json.drops (patient_dilation.patient.get_label_for_allergy("dilationdrops", patient_dilation.drops)).to_s.upcase
    json.advised_by User.find_by(id: patient_dilation.advised_by).try(:fullname).upcase
    json.dilated_by patient_dilation.dilated_by.upcase
    json.comment patient_dilation.comment
  end
end
json.last_dilation @last_dilation
