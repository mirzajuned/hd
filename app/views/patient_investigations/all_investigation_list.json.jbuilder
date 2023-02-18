json.array!(@patient_ophthal_investigations) do |patient_ophthal_investigation|
  json.extract! patient_ophthal_investigation, :id, :created_at, :doctor_name, :facility_id, :patient_id, :record_id, :specalityid, :specalityname, :templatetype, :user_id, :status, :payment, :report_id, :appointment_id

  # json.ophthal_investigations do
  #   json.investigationname patient_ophthal_investigation.ophthal_investigations.investigationname
  # end
  json.encounter_date patient_ophthal_investigation.encounter_date.strftime("%d %b %Y")
  json.patient_org_id PatientIdentifier.find_by(patient_id: patient_ophthal_investigation.patient_id).try(:patient_org_id)
  json.patient_details Patient.find_by(id: patient_ophthal_investigation.patient_id)
  json.unavailable_test_id patient_ophthal_investigation.unavailable_test_id
  json.ophthal_investigations patient_ophthal_investigation.ophthal_investigations
end
