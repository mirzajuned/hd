json.array!(@patient_radio_reports) do |patient_radio_report|
  json.extract! patient_radio_report, :id, :assessment_id, :patient_id, :asset_path, :facility_id, :investigation_id, :investigation_name, :record_id, :upload_id
  json.created_at patient_radio_report.created_at.strftime("%d %b'%y")
  if patient_radio_report.patient_id
    json.patient_name Patient.find(patient_radio_report.patient_id).try(:fullname) || 'NA'
  else
    json.patient_name 'NA'
  end
end
