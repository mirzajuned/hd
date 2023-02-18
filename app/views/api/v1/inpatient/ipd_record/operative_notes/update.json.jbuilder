json.action "update"
json.ipdrecord_id @ipdrecord.id
json.operative_note @operative_note
json.diagnosislist @ipdrecord.diagnosislist
json.procedure @ipdrecord.procedure.where(:operative_note_id.in => [nil, "", @operative_note.try(:id)])
json.clinical_note @ipdrecord.clinical_note
json.advice_set @advice_set
json.procedurenotes_set @procedurenotes_set
json.patient @patient
json.patient_identifier_id @patient.patient_identifier_id
json.patient_mrn @patient.patient_mrn
json.patient_age_gender @patient.patient_age_gender
json.advice_data @advice_data

json.tpa @tpa

# json.bed_details @bed_details

json.admission @admission

user = User.find(@admission.doctor)

json.assigned_doctor user.fullname
json.digital_signature user.digital_signature
json.assigned_doctor_signature user.user_signature_url.to_s

json.facility Facility.find(@admission.facility_id).name

# json.record_histories @clinical_note.record_histories

json.set! "record_histories" do
  json.array!(@operative_note.record_histories) do |list|
    json.action list.action
    json.actiontime list.actiontime
    json.created_at list.created_at
    json.template_type list.template_type
    json.updated_at list.updated_at
    json.user_fullname User.find_by(id: list.user_id.to_s).try(:fullname)
  end
end
