json.status_code 200

# Received Params
json.hospitalCode params[:hospitalCode]
json.mrn params[:mrn]
json.type params[:type]
json.caseID params[:caseID]

# Patient Info
json.patientInfo do
  json.patientName @patient.fullname
  json.gender @patient.gender
  json.dob @patient.dob
  json.age @patient.age
  json.emailId @patient.email
  json.mobileNumber @patient.mobilenumber
  json.address @patient.address_1
  json.pincode @patient.pincode
  json.corporateName 'NA'
  json.employeeId @patient.employee_id
  json.firNumber 'NA'
  json.dateOfIncident @admission.admissiondate.strftime('%d-%b-%Y')
  json.insuranceCompanyName @admission.insurance_name
  json.policyNumber @admission.insurance_policy_no
  json.policyType @admission.insurance_type
  json.tpaName @admission.tpa_name
  json.tpaZone 'NA'
  json.tpaMemberId 'NA'
end

# Medical History
json.medicalHistory do
  json.chiefComplaint '' # 'This is a sample chief complaint'
  json.historyOfPresentingIllness '' # 'Sample history of presenting illness'
  json.pastHistory '' # 'Sample past history'
  json.chronicIllnessHistory do
    json.array!(@patient.personal_history_records) do |personal_history|
      json.name personal_history.name.to_s.titleize
      json.duration personal_history.duration
      json.duration_unit personal_history.duration_unit
      json.notes personal_history.comment
    end
  end
  json.personalHistory do
    json.array!(@patient.personal_history_records) do |personal_history|
      json.name personal_history.name.to_s.titleize
      json.duration personal_history.duration
      json.duration_unit personal_history.duration_unit
      json.notes personal_history.comment
    end
  end
  json.familyHistory []
  json.medicationHistory []
  json.maternityDetails do
    json.notes ''
  end
end

# examinationFindingVOs
json.examinationFindingVOs do
  json.notes ''
end

# Provisional Diagnosis
json.provisionalDiagnosis []

# Final Diagnosis
json.finalDiagnosis do
  json.array!(@diagnoses) do |code, diagnoses|
    json.diagnosisName diagnoses[0].diagnosisname.to_s.titleize
    json.diagnosisType 'Primary'
    json.icdCode code
  end
end

# Billing
json.billing do
  json.dateOfAdmission @admission.admissiondate.strftime('%d-%b-%Y')
  json.dateOfDischarge @admission.dischargedate.try(:strftime, '%d-%b-%Y')
  json.roomType @room_type
  json.rateCard 'GENERAL'
  json.dischargeType 'On Request Discharge'
  json.stayInDays 4
  json.dateOfSurgery @admission.admissiondate.strftime('%d-%b-%Y') # '03-Mar-2018'
  json.actualCostHospitalization 1250000
end

# Treatment
json.treatment do
  json.treatingDoctors do
    json.array!(@doctor.to_a) do |doctor|
      json.department ''
      json.doctorName doctor&.fullname
      json.contactNumber doctor&.mobilenumber
      json.registrationNumber doctor&.registration_number
      json.medicalCouncil ''
    end
  end
end
