json.set! "patients" do
  json.array!(@patient_list) do |patient|
    json.id patient.id
    json.patient_id patient.patient_id
    json.patient_name patient.patient_name
    json.mobile_number patient.mobile_number
    json.patient_identifier_id patient.patient_identifier_id
    json.mr_no patient.mr_no
  end
end
