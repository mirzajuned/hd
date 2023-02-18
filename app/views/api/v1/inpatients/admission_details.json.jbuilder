json.status "success"

json.admission @admission

json.patient_all_data @patient

json.patient do
  json.case_sheet_id @admission.case_sheet_id.to_s
  json.case_sheet_case_id @case_sheet.case_id
  json.case_sheet_name @case_sheet.case_name
  json.case_display_name (("#{@case_sheet.case_name.titleize} - " if @case_sheet.case_name.present?) || "(Click to Add Name) - ") + @case_sheet.case_id.to_s

  json.profile_pic @patient_asset
  json.id "#{@patient.id}"
  json.fullname "#{@patient.fullname}"
  json.patient_org_id "#{PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)}"
  json.mobile_number @patient.mobilenumber.present? ? "#{@patient.mobilenumber}" : "0000000000"
  json.gender @patient.gender.present? ? "#{@patient.gender}" : ""
  json.dob @patient.dob.present? ? @patient.dob.strftime("%d-%m-%Y") : "Unavailable"
  json.age @patient.exact_age.present? ? "#{@patient.exact_age.to_s.split("-").join(" ")}" : ""

  json.initial_patient_referral_type @initial_referral_type
  json.initial_referral_type @initial_referral_type.try(:referral_type)
  json.initial_sub_referral_type @initial_referral_type.try(:sub_referral_type)

  json.primary_language @patient.primary_language
  json.secondary_language @patient.secondary_language
  json.patient_language @patient_language

  json.mr_no PatientOtherIdentifier.find_by(patient_id: @patient.id).present? ? "#{PatientOtherIdentifier.find_by(patient_id: @patient.id).try(:mr_no)}" : ""

  if @patient.patient_type.present?
    json.patient_type_color @patient.patient_type.color
    json.patient_type_label @patient.patient_type.label.to_s.upcase
    json.patient_type_comment @patient.patient_type_comment
  else
    json.patient_type_color ""
    json.patient_type_label ""
    json.patient_type_comment ""
  end

  json.employee_id @patient.employee_id
  json.occupation @patient.occupation
end

json.admission_actions do
  json.discharge_patient @discharge_patient
  json.not_arrived @not_arrived
  json.admitpatient @admitpatient
  json.readmit @readmit
end

json.assigned_doctor User.find(@admission.doctor).fullname

json.admissionstatus @admission_list_view.current_state

json.clinical_note @clinical_note
json.operative_note @operative_note
json.discharge_note @discharge_note
json.ward_notes @ward_notes
json.procedure @procedure

# json.ot_schedules @ot_schedules

json.set! "ot_schedules" do
  json.array!(@ot_schedules) do |ot|
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
