json.action "new"
json.facilities @facilities.pluck(:id, :name)
json.admissiondate @current_date
json.admissiontime @current_time
json.dischargedate @discharge_date
json.dischargetime @discharge_time
json.organisation_id @current_user.organisation_id
json.department_id "486546481"
json.selected_doctor @selected_doctor
json.selected_facility @selected_facility

json.current_doctors @current_doctors.pluck(:id, :fullname)

# json.patient @patient
# if @patient_id.present?
#   json.patient @patient
#   json.patient_history @patient.patient_history
#   json.patient_profile_pic @user_profile_pic_url
#   json.patient_mrn @patient.patient_mrn
#   json.patient_identifier_id @patient.patient_identifier_id
# end

json.patient @patient
if !@patient.blank?
  json.patientallergyhistory @patient.patient_history.try(:patientallergyhistory)
  json.patientpersonalhistory @patient.patient_history.try(:patientpersonalhistory)
  json.patient_mrn @patient.patient_mrn
  json.patient_identifier_id @patient.patient_identifier_id

end

json.set! "ot_schedules" do
  json.array!(@scheduled_ots) do |ot|
    json.id ot.id
    json.admission_id ot.admission_id
    json.bed_id ot.bed_id
    json.bed_type_id ot.bed_type_id
    json.created_at ot.created_at
    json.display_id ot.display_id
    json.facility_id ot.facility_id
    json.is_deleted ot.is_deleted
    json.is_engaged ot.is_engaged
    json.operation_done ot.operation_done
    json.otdate ot.otdate
    json.otendtime ot.otendtime
    json.ottime ot.ottime
    json.patient_id ot.patient_id
    json.procedurename ot.procedurename
    json.surgeonname User.find_by(id: ot.surgeonname.to_s).try(:fullname)

    json.theatrename ot.theatrename
    json.theatreno ot.theatreno
    json.updated_at ot.updated_at
    json.user_id ot.user_id
    json.user_name User.find_by(id: ot.user_id.to_s).try(:fullname)
    json.ward_id ot.ward_id
  end
end
