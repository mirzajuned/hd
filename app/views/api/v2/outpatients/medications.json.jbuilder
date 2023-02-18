json.patient do
  if @current_facility.clinical_workflow
    workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
    json.patient_name @appointment.patient.fullname.upcase
    json.age @appointment.patient.age
    profile_pic = if !@appointment.patient.patientassets.empty?
                    @appointment.patient.patientassets[0].asset_path_url
                  else
                    'https://hg-user-assets.s3.amazonaws.com/profile-pics/592fe79f666d67271794c8e1_photo_20170601_153831.png'
                  end
    json.profile_pic_url profile_pic
    json.gender @appointment.patient.gender
    json.patient_mr_no workflow.patient_display_id
  else
    appointment = AppointmentListView.find_by(appointment_id: params[:appointment_id])
    patient = Patient.find_by(id: appointment.patient_id)
    json.patient_name appointment.patient_name.upcase
    profile_pic = if !patient.patientassets.empty?
                    patient.patientassets[0].asset_path_url
                  else
                    'https://hg-user-assets.s3.amazonaws.com/profile-pics/592fe79f666d67271794c8e1_photo_20170601_153831.png'
                  end
    json.profile_pic_url profile_pic
    json.age appointment.age
    json.gender appointment.patient_gender
    json.patient_mr_no patient.patient_display_id
  end
end
json.medicines @opd_records.each do |record|
  json.id record.id
  date = (record.created_at.to_date == Date.current ? 'Today' : record.created_at.strftime('%d/%m/%Y'))
  doc_name = record.consultant_name.to_s
  json.date date
  json.template_type record.templatetype.titleize.to_s
  json.doctor doc_name
  json.medicine_advised Api::V2::MedicineService.medication_table_json(record, @current_facility,doc_name , date )
end
