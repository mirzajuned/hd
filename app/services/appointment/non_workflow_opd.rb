class Appointment::NonWorkflowOpd
  def initialize(appointment)
    @appointment = appointment
  end

  def create
    set_appointment_type
    set_patient_details
    set_consulting_doctor
    set_scheduling_user
    set_referral_details
    set_appointment_category_type
    set_appointment_specialty

    begin
      AppointmentListView.create(create_attributes)
    rescue Exception => e
      @message = { status: e.status, message: e.message }
    end
  end

  def update
    find_appointment_list_view
    find_clinical_workflow
    find_facility
    set_appointment_type
    set_patient_details
    set_consulting_doctor
    set_scheduling_user
    set_referral_details
    configure_appointment_status
    setup_dilation
    set_start_time
    set_appointment_category_type
    set_appointment_specialty
    @appointment_list_view.update(update_attributes) if @appointment_list_view
  end

  private

  def create_attributes
    {
      specialty_id: @appointment.specialty_id,
      specialty_name: @specialty.name,
      appointment_id: @appointment.id.to_s,
      patient_name: @patient.fullname,
      patient_id: @patient.id,
      patient_display_id: @patient_display_id,
      patient_mr_no: @patient_mr_no,
      patient_age: @patient.exact_age,
      patient_gender: @patient.gender,
      facility_id: @appointment.facility_id,
      consulting_doctor: @consulting_doctor.try(:fullname),
      consulting_doctor_id: @consulting_doctor.try(:id),
      scheduling_user: @scheduling_user.try(:fullname),
      scheduling_user_id: @scheduling_user.try(:id),
      appointment_display_id: @appointment.display_id,
      scheduling_date: @appointment.scheduling_date,
      scheduling_time: @appointment.scheduling_time,
      appointment_date: @appointment.appointmentdate,
      appointment_start_time: @appointment.start_time,
      appointment_type: @appointment_type.try(:label),
      appointment_type_color: @appointment_type.try(:background),
      current_state: "Scheduled",
      current_state_color: "#d9534f",
      referral: @appointment.referral,
      referral_type: @appointment.referral_type,
      intra_referral_id: @appointment.intra_referral_id,
      referral_opd_record: @appointment.referral_opd_record,
      referral_created_on: @appointment.try(:referral_created_on),
      refer_to_facility_name: @appointment.try(:to_facility_name),
      refer_from_facility_name: @appointment.from_facility_name,
      referral_details: @copy_of_referral_details,
      organisation_id: @appointment.organisation_id,
      patient_type: @patient.try(:patient_type_info).present? ? @patient.try(:patient_type_info) : @patient.try(:patient_type).try(:label),
      patient_type_color: @patient.try(:patient_type_info).present? ? '#50100b' : @patient.try(:patient_type).try(:color),
      # patient_type: @appointment.patient.try(:patient_type).try(:label),
      # patient_type_color: @appointment.patient.try(:patient_type).try(:color),
      appointment_type_comment: @appointment_type.try(:comment),
      appointment_category_label: @appointment_category_type.try(:label),
      appointment_category_color: @appointment_category_type.try(:background),
      appointmenttype: @appointment.try(:appointmenttype),
      city: @patient&.city,
      commune: @patient&.commune,
      pincode: @patient&.pincode,
      district: @patient&.district,
      state: @patient&.state,
      patient_mobilenumber: @patient&.mobilenumber,
      age: @patient&.age
    }
  end

  def update_attributes
    {
      specialty_id: @appointment.specialty_id,
      specialty_name: @specialty.name,
      appointment_id: @appointment.id.to_s,
      patient_name: @patient.fullname,
      patient_id: @patient.id,
      patient_display_id: @patient_display_id,
      patient_mr_no: @patient_mr_no,
      patient_age: @patient.exact_age,
      patient_gender: @patient.gender,
      facility_id: @appointment.facility_id,
      consulting_doctor: @consulting_doctor.try(:fullname),
      consulting_doctor_id: @consulting_doctor.try(:id),
      scheduling_user: @scheduling_user.try(:fullname),
      scheduling_user_id: @scheduling_user.try(:id),
      appointment_display_id: @appointment.display_id,
      scheduling_date: @appointment.try(:scheduling_date),
      scheduling_time: @appointment.try(:scheduling_time),
      appointment_date: @appointment.appointmentdate,
      appointment_start_time: @start_time,
      appointment_engaged_time: @appointment.engage_time,
      appointment_end_time: @appointment.seen_time,
      appointment_type: @appointment_type.try(:label),
      appointment_type_color: @appointment_type.try(:background),
      current_state: @current_state,
      current_state_color: @current_state_color,
      dilation_start_time: @appointment.dilation_start_time,
      dilation_end_time: @appointment.dilation_end_time,
      dilation_state: @dilation_state,
      dilation_state_color: @dilation_state_color,
      referral: @appointment.referral,
      referral_type: @appointment.referral_type,
      intra_referral_id: @appointment.intra_referral_id,
      referral_opd_record: @appointment.referral_opd_record,
      referral_created_on: @appointment.try(:referral_created_on),
      refer_to_facility_name: @appointment.try(:to_facility_name),
      refer_from_facility_name: @appointment.from_facility_name,
      referral_details: @copy_of_referral_details,
      organisation_id: @appointment.organisation_id,
      token_number: @appointment.token_number,
      patient_type: @patient.try(:patient_type_info).present? ? @patient.try(:patient_type_info) : @patient.try(:patient_type).try(:label),
      patient_type_color: @patient.try(:patient_type_info).present? ? '#50100b' : @patient.try(:patient_type).try(:color),
      appointment_type_comment: @appointment_type.try(:comment),
      appointment_category_label: @appointment_category_type.try(:label),
      appointment_category_color: @appointment_category_type.try(:background),
      appointmenttype: @appointment.try(:appointmenttype),
      consultancy_type: @appointment.consultancy_type,
      city: @patient&.city,
      commune: @patient&.commune,
      pincode: @patient&.pincode,
      district: @patient&.district,
      state: @patient&.state,
      patient_mobilenumber: @patient&.mobilenumber,
      age: @patient&.age
    }
  end

  def set_consulting_doctor
    @consulting_doctor = User.find_by(id: @appointment.consultant_id)
  end

  def set_scheduling_user
    @scheduling_user = User.find_by(id: @appointment.user_id)
  end

  def set_patient_details
    @patient = @appointment.patient
    @patient_display_id = PatientIdentifier.find_by(patient_id: @appointment.patient_id).try(:patient_org_id)
    @patient_mr_no = PatientOtherIdentifier.find_by(patient_id: @appointment.patient_id).try(:mr_no)
  end

  def set_appointment_type
    @appointment_type = AppointmentType.find_by(id: @appointment.appointment_type_id)
  end

  def set_appointment_category_type
    @appointment_category_type = OrganisationAppointmentCategoryType.find_by(id: @appointment.try(:appointment_category_id))
  end

  def set_appointment_specialty
    @specialty = Specialty.find_by(id: @appointment.specialty_id)
  end

  def set_referral_details
    if @appointment.referral
      if @appointment.intra_referral_id || @appointment.opd_referral_id.present?
        @referring_doctor = @appointment.referring_doctor
        @referee_doctor = @appointment.referee_doctor
        @referral_note = @appointment.referral_note
        @copy_of_referral_details = {}
        if @referring_doctor.present?
          @copy_of_referral_details[@appointment.user_id.to_s + "_0"] = [@referring_doctor, @referral_note, Time.current, @referee_doctor]
        end
      end
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

  def configure_appointment_status
    if @appointment.appointmentstatus == 89925002
      @current_state = "Deleted"
      @current_state_color = "#000"
    else
      if @facility.try(:clinical_workflow)
        if @workflow.try(:state) == "not_arrived"
          @current_state = "Scheduled"
          @current_state_color = "#d9534f"
        elsif @workflow.try(:state) == "complete"
          @current_state = "Completed"
          @current_state_color = "#5cb85c"
        else
          @current_state = "Engaged"
          @current_state_color = "#ff8735"
        end
      else
        if @appointment.current_state == "scheduled"
          @current_state = "Scheduled"
          @current_state_color = "#d9534f"
        elsif @appointment.current_state == "waiting"
          @current_state = "Waiting"
          @current_state_color = "#f0ad4e"
        elsif @appointment.current_state == "engaged"
          @current_state = "Engaged"
          @current_state_color = "#ff8735"
        elsif @appointment.current_state == "incomplete"
          @current_state = "Incompleted"
          @current_state_color = "#d9534f"
        elsif @appointment.current_state == "seen"
          @current_state = "Completed"
          @current_state_color = "#5cb85c"
        end
      end
    end
  end

  def set_start_time
    @start_time = @appointment.start_time if @appointment.arrived_time.nil? || @start_time = @appointment.arrived_time
  end

  def find_appointment_list_view
    @appointment_list_view = AppointmentListView.find_by(appointment_id: @appointment.id)
  end

  def find_clinical_workflow
    @workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
  end

  def find_facility
    @facility = @appointment.facility
  end
end
