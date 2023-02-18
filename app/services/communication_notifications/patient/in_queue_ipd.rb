class CommunicationNotifications::Patient::InQueueIpd
  def initialize(event_id, event_class, type)
    @event_id = event_id
    @event = eval(event_class).find(event_id)
    @event_class = event_class
    @type = type
    if @event_class == 'Admission'
      @doctor = User.includes(:users_setting).find(@event.doctor)
      @appointmentdate = @event.admissiondate
      @patient = ::Patient.find_by(id: @event.patient_id)
      @doctor_settings = @doctor.users_setting
      @facility = Facility.find(@event.facility_id)
      @facility_setting = @facility.facility_setting
      @addmission_date =  @event.admissiontime
      @organisation = Organisation.find_by(id: @doctor.organisation_id)
      @organisations_settings = @organisation.organisations_setting
    end
  end

  def send_whatsapp_notification_instantly
    @sender_number = set_sender_whatsapp_number
    # if @sender_number.present?
    if @type == 'same_day_or_emergency'
      based_on_feature_type(7)
    elsif @type == 'planned_admission'
      based_on_feature_type(8)
    elsif @type == 'admission_rescheduled'
      based_on_feature_type(9)
    elsif @type == 'admission_cancelled'
      based_on_feature_type(10)
    elsif @type == 'discharge_message'
      @appointmentdate = @event.dischargedate
      based_on_feature_type(11)
    end
    # end
  end

  def based_on_feature_type(feature_type)
    @cm_events = CommunicationEvent.where(
      feature_type: feature_type, organisation_id: @organisation.id,
      is_disable: false,
      template_disabled_status: false,
      number_disabled_status: false
    )
    if @cm_events.present?
      if @organisations_settings.try(:organisation_whatsapp_enabled)
        @cm_events.each do |cm_event|
          setup_new_appointment_communication_in_queue(cm_event)
        end
      end
    end
  end

  def setup_new_appointment_communication_in_queue(cm_event)
    set_message(cm_event)
    @communication_in_queue = CommunicationInQueue.new
    @communication_in_queue.organisation_id = @doctor.organisation_id
    @communication_in_queue.facility_id = @facility.id
    @communication_in_queue.sender_id = @doctor.id
    @communication_in_queue.sender_role = @doctor.primary_role
    @communication_in_queue.event_id = @event_id
    @communication_in_queue.event_class = @event_class
    @communication_in_queue.event_name = @type
    @communication_in_queue.recipient_id = @patient.id
    @communication_in_queue.recipient_name = @patient.fullname
    @communication_in_queue.recipient_mobilenumber = @patient.whatsappnumber
    @communication_in_queue.recipient_type = 'patient'
    @communication_in_queue.message_body = @message_body
    @communication_in_queue.is_checked = false
    @communication_in_queue.is_delivered = false
    # set_delivery_timestamp
    @communication_in_queue.save
    if @type == 'same_day_or_emergency' || @type == 'planned_admission' || @type == 'admission_cancelled' || @type == 'discharge_message' || @type == 'admission_rescheduled'
      reminder_type_event_trigger(cm_event, @communication_in_queue)
      whatsapp_msg_trigger_instantly(cm_event, @communication_in_queue)
    end
  end

  def reminder_type_event_trigger(cm_event, communication_in_queue)
    if cm_event.event_type == 0
      if cm_event.reminder_type == 'prior day'
        prior_day_conditions(cm_event, communication_in_queue)
      elsif cm_event.reminder_type == 'same day'
        same_day_conditions(cm_event, communication_in_queue)
      elsif cm_event.reminder_type == '2 day prior' || cm_event.reminder_type == '3 day prior'
        event_reminder_type_conditions(cm_event, communication_in_queue)
      else
        # Reminder and event_type Instantly
        whatsapp_msg_trigger_instantly(cm_event, communication_in_queue)
      end
    end
  end

  def prior_day_conditions(cm_event, communication_in_queue)
    @addmission_date = @event.admissiondate
    if Date.current == @addmission_date
    elsif (Date.current < @addmission_date) && (Date.current == @addmission_date - 1.day)
      time_now = Time.new.strftime('%I:%M%p')
      # communication event reminder time
      reminder_time = Time.parse(cm_event.event_reminder_time)
      current_time = Time.parse(time_now)
      based_on_time_notification_trigger(reminder_time, current_time, cm_event, communication_in_queue)
    elsif Date.current < @event.admissiontime - 1.day
      communication_in_reminder = communication_in_queue.clone
      communication_in_reminder.deliverydate = (@event.admissiondate - 1.day)
      communication_in_reminder.deliverytime = @event.admissiontime
      communication_in_reminder.save
    end
  end

  def based_on_time_notification_trigger(reminder_time, current_time, cm_event, communication_in_queue)
    if reminder_time < current_time && cm_event.trigger_instantly == true
      whatsapp_msg_trigger_instantly(cm_event, communication_in_queue)
    elsif reminder_time > current_time
      communication_in_instantly = communication_in_queue.clone
      communication_in_instantly.deliverydate = Date.current
      communication_in_instantly.deliverytime = reminder_time
      communication_in_instantly.save
      # whatsapp_msg_trigger_instantly(cm_event, communication_in_instantly)
    else
      communication_in_queue.delivery_status = 'No Need'
      communication_in_queue.is_delivered = true
      communication_in_queue.save
    end
  end

  def same_day_conditions(cm_event, communication_in_queue)
    appointment_time = @event.admissiontime.strftime('%I:%M%p')
    reminder_time = Time.parse(appointment_time)
    get_notification_time = reminder_time - cm_event.event_reminder_time.to_i.hour
    scheduled_time = @event.scheduled_time.strftime('%I:%M%p')
    communication_in_reminder = communication_in_queue.clone
    communication_in_reminder.save
    communication_in_reminder.update(deliverydate: @event.scheduled_date, deliverytime: get_notification_time)
    communication_in_queue.deliverydate = Date.current
    communication_in_queue.deliverytime = reminder_time
    communication_in_queue.save
  end

  def event_reminder_type_conditions(cm_event, communication_in_queue)
    @addmission_date = @event.admissiondate
    days = cm_event.reminder_type == '2 day prior' ? 2 : 3
    if Date.current == @event.admissiontime
    elsif (Date.current < @event.admissiontime) && (Date.current == @event.admissiontime - days.day)
      time_now = Time.new.strftime('%I:%M%p')
      # communication event reminder time
      reminder_time = Time.parse(cm_event.event_reminder_time)
      current_time = Time.parse(time_now)
      based_on_time_notification_trigger(reminder_time, current_time, cm_event, communication_in_queue)
    elsif Date.current < @event.admissiontime
      update_communication_in_queue_delivery_date(communication_in_queue, days, @addmission_date, cm_event)
    end
  end

  def update_communication_in_queue_delivery_date(communication_in_queue, days, addmission_date, cm_event)
    reminder_date = addmission_date - days.days
    reminder_time = Time.parse(cm_event.event_reminder_time)
    communication_in_reminder = communication_in_queue.clone
    communication_in_reminder.update(deliverydate: reminder_date, deliverytime: reminder_time)
    communication_in_queue.update(deliverydate: addmission_date, deliverytime: reminder_time)
  end

  def whatsapp_msg_trigger_instantly(cm_event, communication_in_queue)
    @response = CommunicationNotifications::WhatsappNotificationService.call(
      cm_event, communication_in_queue, @organisations_settings
    )
  end

  # def set_delivery_timestamp
  #   if @type == "appointment_scheduled"
  #     @communication_in_queue.deliverydate = Date.current
  #     @communication_in_queue.deliverytime = Time.current
  #   end
  # end

  def set_sender_whatsapp_number
    if @facility.try(:communication_number).present? && @facility.try(:communication_number).try(:is_approved)
      @facility.try(:communication_number).try(:communication_number)
    else
      @organisations_settings.try(:communication_number).try(:communication_number)
    end
  end

  def set_organisation_sms_number
    @organisation.try(:sms_contact_number) || 'XXXXXXXXXX'
  end

  def set_facility_sms_number
    @facility.try(:sms_contact_number) || 'XXXXXXXXXX'
  end

  def set_message(communication_event)
    org_sms_number =  set_organisation_sms_number
    fac_sms_number =  set_facility_sms_number
    map = {
      '{PAT_NAME}' => @patient.try(:fullname).try(:titleize),
      '{DOC_NAME}' => @doctor.try(:fullname).try(:titleize),
      '{ORG_SMS_NUM}' => org_sms_number,
      '{FAC_SMS_NO}' => fac_sms_number,
      '{FAC_NAME}' => @facility.try(:name).try(:titleize),
      '{APP_DATE}' => @appointmentdate.try(:strftime, "%d %b'%y"),
      '{ORG_NAME}' => @organisation.try(:name).try(:titleize),
      '{FAC_ADDR}' => @facility.try(:address).try(:titleize),
      '{APP_TIME}' => @event.admissiontime.try(:strftime, '%I:%M%p')
    }

    re = Regexp.union(map.keys)

    @message_body = communication_event.try(:message_format).gsub(re, map)

  end

  def get_doctor_setting
    @doctor_settings = @facility_setting
  end
end
