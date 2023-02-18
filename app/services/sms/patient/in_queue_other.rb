class Sms::Patient::InQueueOther
  def initialize(event_id, event_class, type)
    @event_id = event_id
    @event = eval(event_class).find(event_id)
    @event_class = event_class
    @type = type
    if @event_class == "Patient"
      @doctor = ""
      @patient = Patient.find_by(id: @event.id)
      @appointmentdate = ''
      @doctor_settings = ""
      @facility = ""
      @organisation = Organisation.find(@event.reg_hosp_ids[0])
      @appointment = Appointment.where(patient_id: @patient.id)
      @organisations_settings = @organisation.organisations_setting
      if @appointment.count > 0
        @facility_setting = @appointment[-1].facility.try(:facility_setting)
      end
    end
  end

  def validate_facility_setting
    if @facility_setting
      if @facility_setting.sms_feature
        prepare
      end
    end
  end

  def prepare
    @sms_in_queue = SmsInQueue.find_by(event_name: @type, event_id: @event_id, is_deleted: false)
    unless @sms_in_queue
      puts "Preparing SMS", "-----------"
      setup_new_appointment_sms_in_queue
    end
  end

  def cancel_prepration
    puts "Cancelling SMS", "------------"
    @sms_inqueue = SmsInQueue.includes(:sms_dispatch).find_by(event_name: @type, event_id: @event_id)
    if @sms_inqueue
      @sms_inqueue.update(is_deleted: true)
      @dispatch_sms = @sms_inqueue.sms_dispatch
      if @dispatch_sms
        @dispatch_sms.update(is_deleted: true)
      end
    end
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

  def self.delete_cancelled_sms_between(start_date, end_date)
    @obsolete_sms = SmsInQueue.where(type: @type, is_deleted: true, :deliverydate => start_date..end_date)
    @obsolete_sms.destory_all
  end

  def set_delivery_timestamp
    if @type == "birthday_sms"
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
  end
end
