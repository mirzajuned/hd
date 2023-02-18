if @current_facility.clinical_workflow
  appointment = Appointment.find_by(id: params[:appointment_id])
  workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
  json.id appointment.id
  json.patient_name appointment.patient.fullname.upcase
  json.age appointment.patient.age
  profile_pic = if !appointment.patient.patientassets.empty?
                  appointment.patient.patientassets[0].asset_path_url
                else
                  ''
                end
  json.profile_pic_url profile_pic
  json.gender appointment.patient.gender
  json.token_number workflow.token_number
  json.patient_mr_no workflow.patient_mr_no.present? ? workflow.patient_mr_no :  workflow.patient_display_id
  json.contact appointment.patient.mobilenumber
  json.language appointment.patient.primary_language
  json.occupation appointment.patient.occupation
  json.appointment_reason workflow.appointment_type_label
  json.appointment_category workflow.appointment_category_label
  json.arrival_time workflow.start_time.try(:strftime, '%I:%M %p')
else
  appointment = AppointmentListView.find_by(appointment_id: params[:appointment_id])
  patient = Patient.find_by(id: appointment.patient_id)
  # json.state appointment.state
  json.id appointment.appointment_id
  json.patient_name appointment.patient_name.upcase
  profile_pic = if !patient.patientassets.empty?
                  patient.patientassets[0].asset_path_url
                else
                  ''
                end
  json.profile_pic_url profile_pic
  json.age appointment.age
  json.gender appointment.patient_gender
  json.patient_mr_no appointment.patient_mr_no.present? ? appointment.patient_mr_no :  appointment.patient_display_id
  json.token_number appointment.token_number
  json.contact appointment.mobile_number
  json.language patient.primary_language
  json.occupation patient.occupation
  json.arrival_time appointment.appointment_start_time.try(:strftime, '%I:%M %p')
  json.appointment_reason appointment.appointment_type
  json.appointment_category appointment.appointment_category_label
end
