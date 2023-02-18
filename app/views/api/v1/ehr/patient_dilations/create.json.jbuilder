json.message @message
json.appointment_id @appointment.id
json.patient_id @appointment.patient_id
json.patient_dilation_id @patient_dilation.id

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

# Expected JSON
# {
#   "appointment_id": "5a1b9e06f9c44c056c685899",
#     "patient_dilation": {
#         "user_id": "58b6d2605e751b4f33110aa6",
#         "appointment_id": "5a1b9e06f9c44c056c685899",
#         "patient_id": "5a0d33baf9c44c056baeaadc",
#         "start_time": "11:35 AM 27/11/2017",
#         "drops": "387526001",
#         "advised_by": "58b6d2605e751b4f33110aa6",
#         "dilated_by": "Hui",
#         "comment": ""
#     }
# }
