json.action "new discharge note"

json.ipdrecord_id @ipdrecord.id

json.ipdrecord @ipdrecord

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
json.patient_age_gender @patient.patient_age_gender

json.bed_details @bed_details

json.admission @admission

json.medication_kit MedicationKit.where(:user_id => current_user.id, :set_type.in => [440654001, 0], :organisation_id => current_user.organisation.id)
