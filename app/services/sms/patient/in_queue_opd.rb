class Sms::Patient::InQueueOpd
  def initialize(event_id, event_class, type)
    @event_id = event_id
    @event = eval(event_class).find(event_id)
    @facility = Facility.find(@event.facility_id)
    @facility_setting = FacilitySetting.find_by(facility_id: @event.facility_id)
    @event_class = event_class
    @type = type
    if @event_class.to_s == "OpdClinicalWorkflow"
      @doctor = User.includes(:users_setting).find(@event.consultant_ids[-1])
      @appointmentdate = @event.appointmentdate
      @patient = ::Patient.find_by(id: @event.patient_id)
      get_doctor_setting
      @organisation = Organisation.find(@doctor.organisation_id)
      @organisations_settings = @organisation.organisations_setting
    elsif @event_class.to_s == "AppointmentListView"
      @doctor = User.includes(:users_setting).find(@event.consulting_doctor_id)
      @appointmentdate = @event.appointment_date
      @patient = ::Patient.find_by(id: @event.patient_id)
      get_doctor_setting
      @organisation = Organisation.find(@doctor.organisation_id)
      @organisations_settings = @organisation.organisations_setting
    elsif @event_class.to_s == "Appointment"
      @doctor = User.includes(:users_setting).find(@event.consultant_id)
      @appointmentdate = @event.appointmentdate
      @patient = ::Patient.find_by(id: @event.patient_id)
      get_doctor_setting
      @organisation = Organisation.find(@doctor.organisation_id)
      @organisations_settings = @organisation.organisations_setting
    end
  end

  def validate_facility_setting
    prepare if @facility_setting.sms_feature
  end

  def prepare
    @sms_in_queue = SmsInQueue.find_by(event_name: @type, event_id: @event_id, is_deleted: false)
    unless @sms_in_queue
      setup_new_appointment_sms_in_queue
    end
  end

  def cancel_prepration
    @sms_inqueue = SmsInQueue.includes(:sms_dispatch).find_by(event_name: @type, event_id: @event_id)
    if @sms_inqueue
      @sms_inqueue.update(is_deleted: true)
      @dispatch_sms = @sms_inqueue.sms_dispatch
      if @dispatch_sms
        @dispatch_sms.update(is_deleted: true)
      end
    end
  end

  def self.delete_cancelled_sms_between(start_date, end_date)
    @obsolete_sms = SmsInQueue.where(type: @type, is_deleted: true, :deliverydate => start_date..end_date)
    @obsolete_sms.destory_all
  end

  def setup_new_appointment_sms_in_queue
    # set message to be sent
    set_message
    @sms_in_queue = SmsInQueue.new
    @sms_in_queue.organisation_id = @doctor.organisation_id
    @sms_in_queue.facility_id = @facility.id
    @sms_in_queue.sender_id = @doctor.id
    @sms_in_queue.sender_role = @doctor.primary_role
    @sms_in_queue.event_id = @event_id
    @sms_in_queue.event_class = @event_class
    @sms_in_queue.event_name = @type
    @sms_in_queue.recipient_id = @patient.id
    @sms_in_queue.recipient_name = @patient.fullname
    @sms_in_queue.recipient_mobilenumber = @patient.mobilenumber
    @sms_in_queue.recipient_type = 'patient'
    @sms_in_queue.message_body = @message_body
    @sms_in_queue.is_checked = false
    @sms_in_queue.is_delivered = false
    # set delivery date and time
    set_delivery_timestamp
    @sms_in_queue.save
  end

  def set_delivery_timestamp
    if @type == "visit_sms"
      @sms_in_queue.deliverydate = @appointmentdate
      visit_sms_time = @facility_setting.visit_sms_time.blank? ? Time.current : @facility_setting.visit_sms_time
      @sms_in_queue.deliverytime = visit_sms_time
    elsif @type == "followup_sms"
      @date = @appointmentdate - @facility_setting.followup_sms_schedule.to_i.days
      if @date <= Date.current
        @appointmentdate = @appointmentdate
      else
        @appointmentdate = @date
      end
      @sms_in_queue.deliverydate = @appointmentdate
      @sms_in_queue.deliverytime = @facility_setting.followup_sms_time.blank? ? Time.current : @facility_setting.followup_sms_time
    elsif @type == "missed_sms"
      @sms_in_queue.deliverydate = @appointmentdate + @facility_setting.missed_sms_schedule.to_i.days
      @sms_in_queue.deliverytime = @facility_setting.missed_sms_time.blank? ? Time.current : @facility_setting.missed_sms_time
    elsif @type == "appointment_sms"
      @sms_in_queue.deliverydate = Date.current
      @sms_in_queue.deliverytime = Time.current
    end
  end

  def set_message
    mobile_number = @organisations_settings.present? && @organisations_settings.try(:sms_contact_enabled) ? ((@organisation.try(:sms_contact_number).present?) ? @organisation.try(:sms_contact_number) : @organisation.try(:telephone)) : ((@facility.try(:sms_contact_number).present?) ? @facility.try(:sms_contact_number) : @facility.try(:telephone))
    map = {
      "{PAT_NAME}" => @patient.try(:fullname).try(:titleize), "{DOC_NAME}" => @doctor.try(:fullname).try(:titleize),
      "{SMS_NO}" => mobile_number, "{FAC_NAME}" => @facility.try(:name).try(:titleize), "{FOL_DATE}" => @appointmentdate.try(:strftime, "%d %b'%y"),
      '{ORG_NAME}' => @organisation.try(:name).try(:titleize)
    }

    re = Regexp.union(map.keys)
    @message_body = @facility_setting.send(@type + "_text").gsub(re, map)

    attach_feedback_link
  end

  def attach_feedback_link
    if @type == 'visit_sms'
      @feedback_template = FeedbackSetting.find_by(organisation_id: @organisation.id, set_type: 'opd')
      if @feedback_template.present?
        if @feedback_template.opd_feedback_feature
          @patient_feedback_url = PatientFeedbackUrl.new.tap do |feedback_url|
            feedback_url.appointment_id = @event.try(:appointment_id)
            feedback_url.organisation_id = @organisation.id
            feedback_url.organisation_name = @organisation.try(:name).try(:capitalize)
            feedback_url.patient_name = @patient.try(:fullname)
            feedback_url.patient_id = @patient.id
            feedback_url.facility_id = @facility.id
            feedback_url.feedback_setting_id = @feedback_template.id
            feedback_url.set_type = 'opd'
            feedback_url.expected_expiry_date = Date.current + 1.month
            feedback_url.doctor_id = @doctor.id
          end
          @patient_feedback_url.generate_short_url
          if @patient_feedback_url.save
            @message_body = @message_body.to_s + " Would you take a moment to rate your experience with us. #{@patient_feedback_url.original_url}"
          end
        end
      end
    end
  end

  def get_doctor_setting
    @doctor_settings = @facility_setting
  end
end
