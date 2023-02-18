json.action "edit"

json.ipdrecord_id @ipdrecord.id

json.ophthal_investigations @ipdrecord.ophthal_investigations_list

json.radiology_investigations @ipdrecord.radiology_investigations_list

json.laboratory_investigations @ipdrecord.laboratory_investigations_list

json.discharge_note @discharge_note

json.diagnosislist @diagnosislist

json.procedure @procedure

json.clinical_note @clinical_note

json.clinical_note_investigation @clinical_note_investigation

json.ots @ots

json.patient @patient

json.patient_identifier_id @patient.patient_identifier_id
json.patient_mrn @patient.patient_mrn
json.patient_age_gender @patient.patient_age_gender
json.tpa @tpa
json.bed_details @bed_details

json.admission @admission

json.assigned_doctor User.find(@admission.doctor).fullname

json.facility Facility.find(@admission.facility_id).name

# json.record_histories @clinical_note.record_histories

json.set! "record_histories" do
  json.array!(@discharge_note.record_histories) do |list|
    json.action list.action
    json.actiontime list.actiontime
    json.created_at list.created_at
    json.template_type list.template_type
    json.updated_at list.updated_at
    json.user_fullname User.find_by(id: list.user_id.to_s).try(:fullname)
  end
end

json.medication_kit MedicationKit.where(:user_id => current_user.id, :set_type.in => [440654001, 0], :organisation_id => current_user.organisation.id)
