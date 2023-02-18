json.set! "patients" do
  json.array!(@patients) do |patient|
    json.id patient.id.to_s
    json.display_id PatientIdentifier.where(:organisation_id => current_user.organisation_id, :patient_id => patient.id).first.try(:patient_org_id)
    json.name patient.fullname
    json.mobilenumber patient.mobilenumber
    json.email patient.email
    json.picthumb patient.patientassets.present? ? patient.patientassets.last.asset_path_url(:api_thumb) : ''
    json.picactual patient.patientassets.present? ? patient.patientassets.last.asset_path_url : ''
    json.age patient.age
    json.gender patient.gender
    json.address_1 patient.address_1
    json.address_2 patient.address_2
    json.city patient.city
    json.state patient.state
    json.pincode patient.pincode
    json.dob patient.dob
  end
end
