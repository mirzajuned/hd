json.action "new clinical note"
json.ipdrecord @ipdrecord
json.patient @patient
json.patient_history @patient.patient_history
json.patient_identifier_id @patient.patient_identifier_id
json.patient_mrn @patient.patient_mrn
json.patient_age_gender @patient.patient_age_gender

json.tpa @tpa

json.assigned_doctor User.find(@admission.doctor).fullname

json.facility Facility.find(@admission.facility_id).name

json.bed_details @bed_details

json.admission @admission

json.opd_records @opd_records
