class Appointment::WorkflowOpd
  def initialize(appointment)
    @appointment = appointment
  end

  def create
    set_patient_details
    set_appointment_type
    set_refrral_details
    set_appointment_category_type
    set_appointment_specialty
    consultant_id_role_ids = User.find_by(id: @appointment.consultant_id.to_s).role_ids
    if consultant_id_role_ids.include? 28229004
      @optometrist_consultant = @appointment.consultant_id.to_s
      @doctor_consultant = ''
    else
      @doctor_consultant = @appointment.consultant_id.to_s
      @optometrist_consultant = ''
    end
    OpdClinicalWorkflow.create!(create_attributes)
  end

  def update
    @workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
    set_patient_details
    set_appointment_type
    set_appointment_category_type
    setup_dilation
    setup_referral_for_update
    set_appointment_specialty

    if @workflow

      case @workflow.state
      when "not_arrived"
        @workflow.update(not_arrived_update_attributes)
      else
        @workflow.update(arrived_update_attributes)
      end

      validate_cancel_workflow
    end
  end

  private

  def create_attributes
    {
      patient_id: @patient.id,
      appointment_id: @appointment.id.to_s,
      facility_id: @appointment.facility_id,
      specialty_id: @appointment.specialty_id,
      specialty_name: @specialty.name,
      # department_id: @appointment.department_id,
      organisation_id: @appointment.organisation_id,
      user_id: @appointment.user_id,
      appointmentdate: @appointment.appointmentdate,
      doctor_ids: [@doctor_consultant],
      optometrist_ids: [@optometrist_consultant],
      consultant_ids: [@appointment.consultant_id.to_s],
      patient_name: @patient.fullname,
      patient_mobilenumber: @patient.mobilenumber,
      patient_age: @patient.age,
      patient_gender: @patient.gender,
      appointment_type_label: @appointment_type.try(:label),
      appointment_type_color: @appointment_type.try(:background),
      patient_display_id: @patient_identifier,
      patient_mr_no: @patient_mrn,
      appointmentstatus: @appointment.appointmentstatus,
      start_time: @appointment.start_time,
      referral: @appointment.referral,
      referral_type: @appointment.referral_type,
      intra_referral_id: @appointment.intra_referral_id,
      referral_opd_record: @appointment.referral_opd_record,
      referring_doctor: @referring_doctor,
      referral_note: @referral_note,
      referee_doctor: @referee_doctor,
      referral_created_on: @appointment.try(:referral_created_on),
      refer_to_facility_name: @appointment.try(:to_facility_name),
      refer_from_facility_name: @appointment.from_facility_name,
      token_number: @appointment.try(:token_number),
      patient_type: @patient.try(:patient_type_info).present? ? @patient.try(:patient_type_info) : @patient.try(:patient_type).try(:label),
      patient_type_color: @patient.try(:patient_type_info).present? ? '#50100b' : @patient.try(:patient_type).try(:color),
      appointment_type_comment: @appointment_type.try(:comment),
      appointment_category_label: @appointment_category_type.try(:label),
      appointment_category_color: @appointment_category_type.try(:background),
      appointmenttype: @appointment.try(:appointmenttype),
      is_qm_enabled: FacilitySetting.find_by(facility_id: @appointment.facility_id).queue_management
    }
  end

  def not_arrived_update_attributes
    {
      specialty_id: @appointment.specialty_id,
      specialty_name: @specialty.name,
      facility_id: @appointment.facility_id,
      appointmentdate: @appointment.appointmentdate,
      appointment_type_label: @appointment_type.try(:label),
      appointment_type_color: @appointment_type.try(:background),
      appointmentstatus: @appointment.appointmentstatus,
      start_time: @appointment.start_time,
      referral: @appointment.referral,
      referral_type: @appointment.referral_type,
      intra_referral_id: @appointment.intra_referral_id,
      referral_opd_record: @appointment.referral_opd_record,
      referral_note: @referral_note,
      referring_doctor: @referring_doctor,
      referee_doctor: @referee_doctor,
      referral_created_on: @appointment.try(:referral_created_on),
      refer_to_facility_name: @appointment.try(:to_facility_name),
      referral_details: @copy_of_referral_details,
      refer_from_facility_name: @appointment.from_facility_name,
      :dilation_start_time => @appointment.dilation_start_time,
      dilation_end_time: @appointment.dilation_end_time,
      dilation_state: @dilation_state,
      dilation_state_color: @dilation_state_color,
      token_number: @appointment.try(:token_number),
      patient_type: @patient.try(:patient_type_info).present? ? @patient.try(:patient_type_info) : @patient.try(:patient_type).try(:label),
      patient_type_color: @patient.try(:patient_type_info).present? ? '#50100b' : @patient.try(:patient_type).try(:color),
      appointment_type_comment: @appointment_type.try(:comment),
      appointment_category_label: @appointment_category_type.try(:label),
      appointment_category_color: @appointment_category_type.try(:background),
      appointmenttype: @appointment.try(:appointmenttype),
      consultancy_type: @appointment.consultancy_type
    }
  end

  def arrived_update_attributes
    {
      specialty_id: @appointment.specialty_id,
      specialty_name: @specialty.name,
      dilation_start_time: @appointment.dilation_start_time,
      dilation_end_time: @appointment.dilation_end_time,
      dilation_state: @dilation_state,
      dilation_state_color: @dilation_state_color,
      appointment_type_label: @appointment_type.try(:label),
      appointment_type_color: @appointment_type.try(:background),
      appointment_category_label: @appointment_category_type.try(:label),
      appointment_category_color: @appointment_category_type.try(:background),
      token_number: @appointment.try(:token_number),
      patient_type: @patient.try(:patient_type_info).present? ? @patient.try(:patient_type_info) : @patient.try(:patient_type).try(:label),
      patient_type_color: @patient.try(:patient_type_info).present? ? '#50100b' : @patient.try(:patient_type).try(:color),
      appointment_type_comment: @appointment_type.try(:comment),
      consultancy_type: @appointment.consultancy_type
    }
  end

  def set_patient_details
    @patient = @appointment.patient
    @patient_identifier = @patient.patient_identifier_id
    @patient_mrn = @patient.patient_mrn
  end

  def set_appointment_type
    @appointment_type = @appointment.appointment_type
  end

  def set_appointment_category_type
    @appointment_category_type = OrganisationAppointmentCategoryType.find_by(id: @appointment.try(:appointment_category_id))
  end

  def set_appointment_specialty
    @specialty = Specialty.find_by(id: @appointment.specialty_id)
  end

  def set_refrral_details
    @referring_doctor = ""
    @referral_note = ""
    @referee_doctor = ""
    if @appointment.referral and @appointment.intra_referral_id.present? || @appointment.opd_referral_id.present?
      @referring_doctor = @appointment.referring_doctor
      @referee_doctor = @appointment.referee_doctor
      @referral_note = @appointment.referral_note
    end
  end

  def setup_dilation
    if @appointment.dilation_start_time == nil && @appointment.dilation_end_time == nil
      @dilation_state = nil
      @dilation_state_color = nil
    elsif @appointment.dilation_start_time != nil && @appointment.dilation_end_time != nil
      @dilation_state = "Dilated"
      @dilation_state_color = "success"
    else
      @dilation_state = "Dilating"
      @dilation_state_color = "danger"
    end
  end

  def setup_referral_for_update
    if @appointment.referral
      if @appointment.intra_referral_id || @appointment.opd_referral_id.present?
        @referring_doctor = @appointment.referring_doctor
        @referee_doctor = @appointment.referee_doctor
        @referral_note = @appointment.referral_note
        unless @workflow.try(:referral_details).present?
          @copy_of_referral_details = {}
          if @referring_doctor.present?
            @copy_of_referral_details[@appointment.user_id.to_s + "_0"] = [@referring_doctor, @referral_note, Time.current, @referee_doctor]
          end
        end
      end
    end
  end

  def validate_cancel_workflow
    @workflow.cancel if @appointment.try(:appointmentstatus).to_i == 89925002
    @workflow.update(state: "not_arrived") if (@appointment.try(:appointmentstatus).to_i == 416774000 and @workflow.try(:state) == "cancelled")
    @counsellor = CounsellorWorkflow.find_by(appointment_id: @appointment.id.to_s).try(:deleted) if @appointment.try(:appointmentstatus).to_i == 89925002
  end
end
