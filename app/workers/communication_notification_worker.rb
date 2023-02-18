class CommunicationNotificationWorker
  attr_accessor :communication_type, :event_id, :event_class
  def initialize(event_type, event_id, event_class)
    @event_type = event_type
    @event = eval(event_class).find_by(id: event_id)
    @event_class = if eval(event_class) < OpdClinicalWorkflow
                     'OpdClinicalWorkflow'
                   else
                     event_class
                   end
    if @event
      @facility = Facility.includes(:facility_setting).find_by(id: @event.facility_id)
      @facility_setting = @facility.facility_setting rescue nil
    end
    # set_facility
  end

  def call
    if @event_type == 'appointment_scheduled' || @event_type == 'patient_arrived' || @event_type == 'mark_as_completed' || @event_type == 'reschedule_appointment' || @event_type == 'cancel_appointment' || @event_type == "appointment_walkin"
      CommunicationNotifications::Patient::InQueueOpd.new(@event.id, @event_class, @event_type).send_whatsapp_notification_instantly
    elsif  @event_type == 'same_day_or_emergency' ||  @event_type == 'planned_admission' ||  @event_type == 'admission_rescheduled' ||  @event_type == 'admission_cancelled' || @event_type == 'discharge_message'
      CommunicationNotifications::Patient::InQueueIpd.new(@event.id, @event_class, @event_type).send_whatsapp_notification_instantly
    elsif  @event_type == 'optical_glass_prescription_advised_patient' || @event_type == 'optical_glass_prescription_advised_store'  || @event_type == 'optical_order_placed' || @event_type == 'optical_fitting' || @event_type == 'optical_ready' || @event_type == 'optical_delivered' || @event_type == 'optical_order_cancelled' || @event_type == 'optical_bill_cancelled' || @event_type == 'optical_return' || @event_type == 'pharmacy_patient' || @event_type == 'pharmacy_store' || @event_type == "pharmacy_bill_cancelled" || @event_type == 'pharmacy_return' || @event_type == 'optical_bill_creation' || @event_type == 'pharmacy_order_placed' || @event_type == 'pharmacy_bill_creation'
      CommunicationNotifications::Patient::InQueueOptical.new(@event.id, @event_class, @event_type).send_whatsapp_notification_instantly
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
