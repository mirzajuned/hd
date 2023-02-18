json.set! "patients" do
  json.array!(@patient) do |patient|
    ps = PatientSearch.find_by(patient_id: patient.id.to_s)
    # puts ps,"===================="
    json.patient patient

    json.patient_id patient.id
    json.patient_name patient.fullname
    json.mobile_number patient.mobilenumber
    json.patient_identifier_id ps.try(:patient_identifier_id)
    json.mr_no ps.try(:mr_no)

    json.picthumb patient.patientassets.present? ? patient.patientassets.last.asset_path_url(:api_thumb) : ''
    json.picactual patient.patientassets.present? ? patient.patientassets.last.asset_path_url : ''

    if !patient.blank?
      patient_self_history = PatientSelfHistory.where(patient_id: patient.id).order_by('created_at DESC').first
      json.patientallergyhistory patient_self_history.try(:patientallergyhistory)
      json.patientpersonalhistory patient_self_history.try(:patientpersonalhistory)
    end
  end
end

json.organisation_id @organisation_id
json.patient_present @patient_present
json.message @message
