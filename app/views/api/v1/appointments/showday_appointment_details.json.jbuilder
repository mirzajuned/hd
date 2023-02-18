if @facility.clinical_workflow
  json.status 'success'
  json.fac_clinical_wf true
  json.patient do
    json.case_sheet_id @appointment.case_sheet_id.to_s
    json.case_sheet_case_id @case_sheet.case_id
    json.case_sheet_name @case_sheet.case_name
    json.case_display_name (("#{@case_sheet.case_name.titleize} - " if @case_sheet.case_name.present?) || '(Click to Add Name) - ') + @case_sheet.case_id.to_s

    json.show_switch_case (@case_sheet.case_switchable_opd[@appointment.id.to_s].present? && @case_sheet.case_switchable_opd[@appointment.id.to_s][:case_switchable])

    json.profile_pic @patient_asset
    json.id (@appointment.patient.id).to_s
    json.fullname (@appointment.patient.fullname).to_s
    json.patient_org_id (PatientIdentifier.find_by(patient_id: @appointment.patient.id.to_s).try(:patient_org_id)).to_s
    json.mobile_number @appointment.patient.mobilenumber.present? ? (@appointment.patient.mobilenumber).to_s : '0000000000'
    json.gender @appointment.patient.gender.present? ? (@appointment.patient.gender).to_s : ''
    json.dob @appointment.patient.dob.present? ? @appointment.patient.dob.strftime('%d-%m-%Y') : 'Unavailable'
    json.age @appointment.patient.exact_age.present? ? (@appointment.patient.exact_age.to_s.split('-').join(' ')).to_s : ''

    json.initial_patient_referral_type @initial_patient_referral_type
    json.initial_referral_type @initial_patient_referral_type.try(:referral_type)
    json.initial_sub_referral_type @initial_patient_referral_type.try(:sub_referral_type)

    # json.previous_referral_present @total_patient_referrals > 1  ? true : false
    json.current_patient_referral_type @patient_referral_type
    json.current_referral_type @patient_referral_type.try(:referral_type)
    json.current_sub_referral_type @patient_referral_type.try(:sub_referral_type)

    json.deleted_patient_referral @deleted_patient_referral_type

    json.primary_language @patient.primary_language
    json.secondary_language @patient.secondary_language
    json.patient_language @patient_language

    json.mr_no PatientOtherIdentifier.find_by(patient_id: @appointment.patient.id).present? ? (PatientOtherIdentifier.find_by(patient_id: @appointment.patient.id).try(:mr_no)).to_s : ''
    json.current_status @clinical_workflow.state
    json.is_arrived @clinical_workflow.state != 'not_arrived'
    json.button_is_completed @clinical_workflow.state == 'complete'

    if @patient.patient_type.present?
      json.patient_type_color @patient.patient_type.color
      json.patient_type_label @patient.patient_type.label.to_s.upcase
      json.patient_type_comment @patient.patient_type_comment
    else
      json.patient_type_color ''
      json.patient_type_label ''
      json.patient_type_comment ''
    end
    if current_facility.country_id == 'VN_254'
      json.occupation @occupation_name
    else
      json.occupation @patient.occupation
    end
    json.employee_id @patient.employee_id
    json.special_patient @special_patient
    json.color @color
    json.one_eye @one_eye
    json.eye_color @eye_color
  end

  json.consultant User.find_by(id: @clinical_workflow.consultant_ids[-1]).fullname
  json.eyedrop_allergy @eyedrop_allergy

  json.workflow_id @clinical_workflow.id

  json.with_user_id @clinical_workflow.user_id
  json.with_department_id @clinical_workflow.department_id

  json.wf_users do
    json.receptionist @current_facility_receptionists_arr
    json.optometrist @current_facility_optometrists_arr
    json.doctor @current_facility_doctors_arr
    json.nurse @current_facility_nurses_arr
    json.counsellor @current_facility_counsellors_arr
    json.department @current_facility_departments_arr
  end

  appointment_actions = []

  if @clinical_workflow.state == 'not_arrived'
    appointment_actions << "Mark Patient Arrived" if @current_date.to_s == Date.current.to_s
  end
  if @clinical_workflow.state == 'check_out' && @clinical_workflow.user_id.to_s == @current_user.id.to_s
    appointment_actions << 'Check-In'
  end
  if @clinical_workflow.state != 'complete' && ['doctor', 'receptionist', 'counsellor', 'optometrist', 'check_out'].include?(@clinical_workflow.state)
    appointment_actions << "NA" if @clinical_workflow_timeline.count == 1
    if @clinical_workflow.try(:user_id) == @current_user.id.to_s
      unless @clinical_workflow_timeline.count == 1 || @current_user.role_ids.include?(499992366) # counsellor
        appointment_actions << 'Mark as Away'
      end
      appointment_actions << 'Mark as Completed'
    end
  end

  if @clinical_workflow.state == 'complete'
    # if @clinical_workflow.try(:user_id) == @current_user.id.to_s
    if @clinical_workflow_timeline[@clinical_workflow_timeline_count - 2].try(:user_id).to_s == @current_user.id.to_s
      appointment_actions << 'Undo'
    end
    # end
  else
    if @clinical_workflow.try(:user_id) != @current_user.id.to_s
      if @clinical_workflow_timeline[@clinical_workflow_timeline_count - 2].try(:user_id).to_s == @current_user.id.to_s
        appointment_actions << 'Undo'
      end
    end
  end

  unless @clinical_workflow.state == 'complete' || @clinical_workflow.state == 'not_arrived' || @clinical_workflow.try(:user_id) == @current_user.id.to_s || @current_user.has_role?(:counsellor) || @clinical_workflow.state == 'away'
    appointment_actions << 'Get Patient'
  end

  appointment_actions << "Get Patient" if @clinical_workflow.state == "away"

  json.appointment_actions appointment_actions

  json.state_diagram do
    state_array = []
    if @clinical_workflow.state != 'not_arrived'
      state_array << { state: 'Arrived', role_abbr: '', role: '', time_diff: '', color: '#f0ad4e' }

      @clinical_workflow.opd_clinical_workflow_state_transitions.each do |transition|
        state = if transition.to == 'incomplete'
                  'Incompleted'
                elsif transition.to == 'complete'
                  'Completed'
                elsif transition.to == 'away'
                  'Away'
                elsif transition.to == 'check_out'
                  "CO: #{User.find_by(id: transition.user_id).try(:fullname)&.titleize}"
                elsif transition.department_id != nil
                  Department.find_by(id: transition.department_id).name
                else
                  User.find_by(id: transition.user_id).try(:fullname).titleize
                end

        role_abbr = if transition.to == 'incomplete'
                      ''
                    elsif transition.to == 'complete'
                      ''
                    elsif transition.to == 'away'
                      ''
                    elsif transition.to == 'check_out'
                      ''
                    elsif transition.department_id != nil
                      Department.find_by(id: transition.department_id).name
                    else
                      User.find_by(id: transition.user_id).selected_role[0..2]
                    end

        time_diff = if transition.to == 'complete'
                      ''
                    elsif transition.transition_end.nil?
                      TimeDifference.between(Time.current, transition.transition_start).in_seconds
                    else
                      TimeDifference.between(transition.transition_end, transition.transition_start).in_seconds
                    end

        department_array = ['ophthal_investigation', 'radiology_investigation', 'laboratory_investigation',
                            'optical', 'pharmacy']
        color = if department_array.include? transition.to
                  '#428bca'
                elsif transition.to == 'complete'
                  '#1CAF9A'
                else
                  '#777'
                end

        state_array << { state: state, role_abbr: role_abbr, role: transition.to, time_diff: time_diff, color: color }
      end
    end
    json.states state_array
  end
  json.appointment do
    json.id (@appointment.id).to_s
    json.identifier (PatientIdentifier.find_by(patient_id: @appointment.patient.id.to_s).try(:patient_org_id)).to_s
    json.scheduled_by (User.find(@appointment.user_id).fullname).to_s
    json.appointent_type (@appointment.try(:appointment_type).try(:label)).to_s
    json.appointent_type_color (@appointment.try(:appointment_type).try(:background)).to_s
    json.dilation_start_time (@appointment.dilation_start_time).to_s
    json.dilation_end_time (@appointment.dilation_end_time).to_s
  end
else

  json.status 'success'
  json.patient do
    json.profile_pic @patient_asset
    json.id (@appointment.patient.id).to_s
    json.fullname (@appointment.patient.fullname).to_s
    json.patient_org_id (PatientIdentifier.find_by(patient_id: @appointment.patient.id.to_s).try(:patient_org_id)).to_s
    json.mobile_number @appointment.patient.mobilenumber.present? ? (@appointment.patient.mobilenumber).to_s : '0000000000'
    json.gender @appointment.patient.gender.present? ? (@appointment.patient.gender).to_s : ''
    json.dob @appointment.patient.dob.present? ? @appointment.patient.dob.strftime('%d-%m-%y') : 'Unavailable'
    json.age @appointment.patient.exact_age.present? ? (@appointment.patient.exact_age.to_s.split('-').join(' ')).to_s : ''
    json.case_sheet_id @appointment.case_sheet_id.to_s
    json.case_sheet_case_id @case_sheet.case_id
    json.case_sheet_name @case_sheet.case_name
    json.case_display_name (("#{@case_sheet.case_name.titleize} - " if @case_sheet.case_name.present?) || '(Click to Add Name) - ') + @case_sheet.case_id.to_s

    json.initial_patient_referral_type @initial_patient_referral_type
    json.initial_referral_type @initial_patient_referral_type.try(:referral_type)
    json.initial_sub_referral_type @initial_patient_referral_type.try(:sub_referral_type)

    # json.previous_referral_present @total_patient_referrals > 1  ? true : false
    json.current_patient_referral_type @patient_referral_type
    json.current_referral_type @patient_referral_type.try(:referral_type)
    json.current_sub_referral_type @patient_referral_type.try(:sub_referral_type)

    json.primary_language @patient.primary_language
    json.secondary_language @patient.secondary_language
    json.patient_language @patient_language

    json.mr_no PatientOtherIdentifier.find_by(patient_id: @appointment.patient.id).present? ? (PatientOtherIdentifier.find_by(patient_id: @appointment.patient.id).try(:mr_no)).to_s : ''
    json.current_status @appointment_list_view.current_state
  end

  json.consultant @appointment_list_view.consulting_doctor
  json.eyedrop_allergy @eyedrop_allergy

  state_array = []
  unless @appointment_list_view.current_state == 'Scheduled'
    if @appointment_list_view.current_state != 'Scheduled'
      state_array << 'Arrived'
      state_array << 'Waiting'
    end
    if @appointment_list_view.current_state == 'Engaged' || @appointment_list_view.current_state == 'Completed'
      state_array << "Engaged" if @appointment_list_view.appointment_engaged_time.present?
    end
    state_array << "Completed" if @appointment_list_view.current_state == "Completed"
    state_array << "InCompleted" if @appointment_list_view.current_state == "Incompleted"
  end
  json.states state_array

  appointment_actions = []

  if @current_date.to_s <= Date.current.to_s
    if @appointment_list_view.current_state == 'Scheduled'
      appointment_actions << 'Patient Arrived'
    elsif @appointment_list_view.current_state == 'Waiting'
      appointment_actions << 'NA'
      appointment_actions << 'Mark Engaged'
      appointment_actions << 'Mark Completed'
    elsif @appointment_list_view.current_state == 'Engaged'
      appointment_actions << 'Undo'
      appointment_actions << 'Mark Completed'
    elsif @appointment_list_view.current_state == 'Completed'
      appointment_actions << 'Reverse Completed'
    end
  end
  json.appointment_actions appointment_actions

  json.appointment do
    json.id (@appointment.id).to_s
    json.identifier (PatientIdentifier.find_by(patient_id: @appointment.patient.id.to_s).try(:patient_org_id)).to_s
    json.scheduled_by (User.find(@appointment.user_id).fullname).to_s
    json.appointent_type (@appointment.appointment_type.label).to_s
    json.appointent_type_color (@appointment.appointment_type.background).to_s
    json.dilation_start_time (@appointment.dilation_start_time).to_s
    json.dilation_end_time (@appointment.dilation_end_time).to_s
  end
end

new_templates_array = []
todays_template_array = []
old_template_array = []

if @current_user.role_ids.include?(158965000) || @current_user.role_ids.include?(106292003) || @current_user.role_ids.include?(28229004)
  if @speciality_folder_name == 'ophthalmology'
    @opd_templates.each do |opd_template_name|
      # opd_record = @appointment_opd_records.find_by(templatetype: "#{opd_template_name['templatename']}")
      # if opd_record.nil?

      #   new_templates_array << { specalityfoldername: @speciality_folder_name, templatetype: "#{opd_template_name['templatename']}", displayname: "#{opd_template_name['displayname']}"}
      # else
      #   new_templates_array << { specalityfoldername: @speciality_folder_name, templatetype: "#{opd_template_name['templatename']}", displayname: "#{opd_template_name['displayname']}", count: opd_record}
      # end
      opd_record = @appointment_opd_records.where(templatetype: (opd_template_name['templatename']).to_s)
      if !opd_record.empty?
        new_templates_array << { specalityfoldername: @speciality_folder_name, templatetype: (opd_template_name['templatename']).to_s, displayname: (opd_template_name['displayname']).to_s, count: opd_record.length }
      else
        new_templates_array << { specalityfoldername: @speciality_folder_name, templatetype: (opd_template_name['templatename']).to_s, displayname: (opd_template_name['displayname']).to_s, count: 0 }
      end
    end
  else
    opd_record = @appointment_opd_records.where(templatetype: 'freeform')
    if !opd_record.empty?
      new_templates_array << { specalityfoldername: @speciality_folder_name, templatetype: 'freeform', displayname: 'Free Form', count: opd_record.length }
    else
      new_templates_array << { specalityfoldername: @speciality_folder_name, templatetype: 'freeform', displayname: 'Free Form', count: 0 }
    end
  end

  if @clinical_workflow.try(:state) != 'not_arrived' || !@clinical_workflow_present
    if !@appointment_opd_records.empty?

      @appointment_opd_records.order(created_at: :desc).each do |appointment_record|
        user = @users.find_by(id: appointment_record.record_histories.order(created_at: :asc)[0].user_id) || User.find_by(id: @current_user.id)
        fullname = ('|' + 'Dr.' + user.try(:fullname).to_s if user.has_role?(:doctor)) || user.try(:fullname).to_s

        todays_template_array << { opdrecordid: appointment_record.id, patientid: @patient.id, appointmentid: @appointment.id, specality: appointment_record.specalityid, templatetype: appointment_record.templatetype, displayname: appointment_record.templatetype.split('_').join(' ').capitalize + fullname.split(' ')[0] }
      end
    end
  end

  if !@old_records.empty?
    @old_records.each do |old_record|
      opd_record = @appointment_opd_records.find_by(templatetype: old_record.templatetype)

      clone = if opd_record
        false
      else
        true
              end

      old_template_array << { displayname: old_record.templatetype.split('_').map(&:capitalize).join(' ') + old_record.encounterdate.strftime('%d%b%y'), opdrecordid: old_record.record_id, patientid: @patient.id, appointmentid: old_record.appointment_id, specality: old_record.specalityid, templatetype: old_record.templatetype, specalityfoldername: @speciality_folder_name, clone: clone }
    end
  end
end

json.new_templates_array new_templates_array
json.todays_template_array todays_template_array
json.old_template_array old_template_array

json.set! 'patient_dilation_list' do
  json.array!(@patient_dilation_list) do |patient_dilation|
    json.id patient_dilation.id
    json.user_id patient_dilation.user_id
    json.appointment_id patient_dilation.appointment_id
    json.patient_id patient_dilation.patient_id
    json.start_time patient_dilation.try(:start_time)
    json.end_time patient_dilation.try(:end_time)
    json.drops patient_dilation.patient.get_label_for_allergy('dilationdrops', patient_dilation.drops).to_s.upcase
    json.advised_by User.find_by(id: patient_dilation.advised_by).try(:fullname).upcase
    json.dilated_by patient_dilation.dilated_by.upcase
    json.comment patient_dilation.comment
  end
end

if @patient_dilation.present?
  json.set! 'patient_dilation' do
    json.id @patient_dilation.id
    json.user_id @patient_dilation.user_id
    json.appointment_id @patient_dilation.appointment_id
    json.patient_id @patient_dilation.patient_id
    json.start_time @patient_dilation.try(:start_time)
    json.end_time @patient_dilation.try(:end_time)
    json.drops @patient_dilation.patient.get_label_for_allergy('dilationdrops', @patient_dilation.drops).to_s.upcase
    json.advised_by User.find_by(id: @patient_dilation.advised_by).try(:fullname).upcase
    json.dilated_by @patient_dilation.dilated_by.upcase
    json.comment @patient_dilation.comment
  end
end

json.eyedrop_allergy @eyedrop_allergy
json.available_specialties @org_specialties
