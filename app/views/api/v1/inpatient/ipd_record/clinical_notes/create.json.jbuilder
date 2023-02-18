json.action "create"
json.ipdrecord @ipdrecord

json.ophthal_investigations @ipdrecord.ophthal_investigations_list
json.radiology_investigations @ipdrecord.radiology_investigations_list
json.laboratory_investigations @ipdrecord.laboratory_investigations_list

json.patient @patient

json.patient_history @patient.patient_history

json.patient_identifier_id @patient.patient_identifier_id
json.patient_mrn @patient.patient_mrn
json.patient_age_gender @patient.patient_age_gender

json.tpa @tpa
json.patient_age_gender @patient.patient_age_gender

json.bed_details @bed_details

json.admission @admission

user = User.find(@admission.doctor)

json.assigned_doctor user.fullname
json.digital_signature user.digital_signature
json.assigned_doctor_signature user.user_signature_url.to_s

json.facility Facility.find(@admission.facility_id).name

# json.record_histories @clinical_note.record_histories

json.set! "record_histories" do
  json.array!(@clinical_note.record_histories) do |list|
    json.action list.action
    json.actiontime list.actiontime
    json.created_at list.created_at
    json.template_type list.template_type
    json.updated_at list.updated_at
    json.user_fullname User.find_by(id: list.user_id.to_s).try(:fullname)
  end
end

json.opd_records @opd_records

# json.clinical_note @clinical_note
