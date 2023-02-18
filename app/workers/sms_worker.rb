class SmsWorker
  attr_accessor :sms_type, :event_id, :event_class
  def initialize(sms_type, event_id, event_class)
    # @sms_logger = Logger.new("#{Rails.root}/log/sms_logger.log")
    @sms_type = sms_type
    @event = eval(event_class).find_by(id: event_id)
    @event_class = if eval(event_class) < OpdClinicalWorkflow
                     'OpdClinicalWorkflow'
                   else
                     event_class
                   end
    if @event
      @facility = Facility.includes(:facility_setting).find_by(id: @event.facility_id)
      @facility_setting = @facility.facility_setting rescue nil
      # @sms_logger.info(" ==== facility_setting: #{@facility_setting.inspect}")
    end
    @workflow_followup_sms_on_facilities = []
    @workflow_missed_sms_on_facilities = []
    @nonworkflow_followup_sms_on_facilities = []
    @nonworkflow_missed_sms_on_facilities = []
    set_facility
  end

  def call
    # @sms_logger.info(" ==== sms_type: #{@sms_type}")
    # @sms_logger.info(" ==== visit_sms_active_inactive: #{@facility_setting.try(:visit_sms_active_inactive)}")
    # @sms_logger.info(" ==== appointment_sms_active_inactive: #{@facility_setting.try(:appointment_sms_active_inactive)}")
    if @sms_type == 'visit_sms' && @facility_setting.try(:visit_sms_active_inactive) == true
      Sms::Patient::InQueueOpd.new(@event.id, @event_class, @sms_type).validate_facility_setting
    elsif @sms_type == 'followup_sms' && @facility_setting.try(:followup_sms_active_inactive).present?
      prepare_sms_for_followup_appointments
    elsif @sms_type == 'missed_sms' && @facility_setting.try(:missed_sms_active_inactive) == true
      prepare_sms_for_missed_appointments
    elsif @sms_type == 'birthday_sms' && @facility_setting.try(:birthday_sms_active_inactive) == true
      prepare_birthday_sms
    elsif @sms_type == 'discharge_sms' && @facility_setting.try(:discharge_sms_active_inactive) == true
      Sms::Patient::InQueueIpd.new(@event.id, @event_class, @sms_type).validate_facility_setting
    elsif @sms_type == 'cancel_sms'
      Sms::Patient::InQueueOpd.new(@event.id, @event_class, @sms_type).cancel_prepration if @event.present? && @event.id
    elsif @sms_type == 'overdue_sms' && @facility_setting.try(:long_overdue_sms_active_inactive) == true
      get_long_overdue_appointments
    elsif @sms_type == 'appointment_sms' && @facility_setting.try(:appointment_sms_active_inactive) == true
      Sms::Patient::InQueueOpd.new(@event.id, @event_class, @sms_type).validate_facility_setting
    end
  end

  def prepare_sms_for_followup_appointments
    @workflow_followups = OpdClinicalWorkflow.where(appointmentdate: Date.current + 1..Date.current + 8.days, :state => 'not_arrived', :facility_id.in => @workflow_followup_sms_on_facilities)
    @nonworkflow_followups = AppointmentListView.where(appointment_date: Date.current + 1..Date.current + 8.days, :current_state => 'scheduled', :facility_id.in => @nonworkflow_followup_sms_on_facilities)

    @workflow_followups.each do |appointment|
      Sms::Patient::InQueueOpd.new(appointment.id, @event_class, @sms_type).validate_facility_setting
    end

    @nonworkflow_followups.each do |appointment|
      Sms::Patient::InQueueOpd.new(appointment.id, @event_class, @sms_type).validate_facility_setting
    end
  end

  def get_long_overdue_appointments; end

  def prepare_sms_for_missed_appointments
    @workflow_missed = OpdClinicalWorkflow.where(appointmentdate: Date.current - 1, :state => 'not_arrived', :facility_id.in => @workflow_missed_sms_on_facilities)
    @nonworkflow_missed = OpdClinicalWorkflow.where(appointmentdate: Date.current - 1, :state => 'not_arrived', :facility_id.in => @nonworkflow_missed_sms_on_facilities)

    @workflow_missed.each do |appointment|
      Sms::Patient::InQueueOpd.new(appointment.id, @event_class, @sms_type).validate_facility_setting
    end
    @nonworkflow_missed.each do |appointment|
      Sms::Patient::InQueueOpd.new(appointment.id, @event_class, @sms_type).validate_facility_setting
    end
  end

  def prepare_birthday_sms
    @birthday = PatientBirthday.where(dob: Date.current.strftime('%d%m'))
    @birthday.each do |bday|
      Sms::Patient::InQueueOther.new(bday.patient_id, @event_class, @sms_type).validate_facility_setting
    end
  end

  def set_facility
    facility_workflow = Facility.includes(:facility_setting).where(clinical_workflow: true, is_active: true)
    facility_workflow.each do |fac|
      next unless fac.facility_setting.try(:sms_feature).present?

      if fac.facility_setting.try(:sms_feature)
        @workflow_followup_sms_on_facilities << fac.id.to_s if fac.facility_setting.followup_sms_active_inactive
        @workflow_missed_sms_on_facilities << fac.id.to_s if fac.facility_setting.missed_sms_active_inactive
      end
    end
    facility_nonworkflow = Facility.includes(:facility_setting).where(clinical_workflow: false, is_active: true)
    facility_nonworkflow.each do |fac|
      next unless fac.try(:facility_setting).present?

      if fac.facility_setting.try(:sms_feature)
        @nonworkflow_followup_sms_on_facilities << fac.id.to_s if fac.facility_setting.followup_sms_active_inactive
        @nonworkflow_missed_sms_on_facilities << fac.id.to_s if fac.facility_setting.missed_sms_active_inactive
      end
    end
  end
end
