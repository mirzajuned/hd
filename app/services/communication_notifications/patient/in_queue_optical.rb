class CommunicationNotifications::Patient::InQueueOptical
  def initialize(event_id, event_class, type)
    @event_id = event_id
    @event = eval(event_class).find(event_id)
    @facility = Facility.find(@event.facility_id)
    @facility_setting = FacilitySetting.find_by(facility_id: @event.facility_id)
    @event_class = event_class
    @type = type
    get_doctor_setting
    @inventory_invoice  = Invoice::InventoryInvoice.find_by(id: @event.try(:invoice_id)) rescue nil
    if @type == 'optical_order_placed' || @type == 'optical_fitting' || @type == 'optical_ready' || @type == 'optical_delivered' || @type == 'optical_order_cancelled' || @type == 'optical_return' || @type == 'optical_bill_cancelled' || @type == 'pharmacy_bill_cancelled' || @type == 'pharmacy_return' || @type == 'pharmacy_bill_creation' || @type == 'optical_bill_creation'
      @patient = ::Patient.find_by(id: @event.patient_id)
      @organisation = Organisation.find_by(id: @event.organisation_id)
      @organisations_settings = @organisation.organisations_setting
      @fitter = Inventory::Fitter.find_by(id: @event.try(:fitter_id))
      @optical_store = Inventory::Store.find_by(id: @event.store_id) rescue nil
    elsif @type == 'pharmacy_patient' || @type == 'pharmacy_store' || @type == 'pharmacy_order_placed'
      @doctor = User.includes(:users_setting).find(@event.consultant_id)  rescue nil
      @patient = ::Patient.find_by(id: (@event.try(:patientid) || @event.try(:patient_id)))
      @organisation = Organisation.find(@event.organisation_id)
      @organisations_settings = @organisation.organisations_setting
      @pharmacy_store = Inventory::Store.find_by(id: @event.try(:view_pharmacy_store_id))
      if @pharmacy_store.nil?
        @pharmacy_store = Inventory::Store.find_by(id: (@event.try(:pharmacy_store_id) || @event.try(:store_id)))
      end
    elsif @type == 'optical_glass_prescription_advised_patient' || @type == 'optical_glass_prescription_advised_store'
      @patient = ::Patient.find_by(id: (@event.try(:patientid) || @event.try(:patient_id)))
      @optometrist = User.find_by(id: @event.try(:optometrist_id))
      @organisation = Organisation.find_by(id: @event.organisation_id)
      @organisations_settings = @organisation.organisations_setting
      @doctor = User.includes(:users_setting).find(@event.consultant_id) rescue nil 
      @optical_store = Inventory::Store.find_by(id: @event.try(:view_optical_store_id))
      if @optical_store.nil?
        @optical_store = Inventory::Store.find_by(id: (@event.try(:optical_store_id) || @event.try(:store_id)))
      end
    else
      @optical_store = Inventory::Store.find_by(id: @event.view_optical_store_id)
      if @optical_store.nil?
        @optical_store = Inventory::Store.find_by(id: @event.optical_store_id)
      end
      @doctor = User.includes(:users_setting).find(@event.consultant_id)
      @patient = ::Patient.find_by(id: @event.patientid)
      @organisation = Organisation.find(@doctor.organisation_id)
      @organisations_settings = @organisation.organisations_setting
    end
  end

  def send_whatsapp_notification_instantly
    if @type == 'optical_glass_prescription_advised_patient'
      based_on_feature_type(12)
    elsif @type == 'optical_glass_prescription_advised_store'
      based_on_feature_type(13)
    elsif @type == 'optical_order_placed'
      based_on_feature_type(14)
    elsif @type == 'optical_fitting'
      based_on_feature_type(15)
    elsif @type == 'optical_ready'
      based_on_feature_type(16)
    elsif @type == 'optical_delivered'
      based_on_feature_type(17)
    elsif @type == 'optical_order_cancelled'
      based_on_feature_type(18)
    elsif @type == 'optical_return'
      based_on_feature_type(19)
    elsif @type == 'optical_bill_cancelled'
      based_on_feature_type(20)
    elsif @type == 'pharmacy_patient'
      based_on_feature_type(21)
    elsif @type == 'pharmacy_store'
      based_on_feature_type(22)
    elsif @type == 'pharmacy_sale_invoice'
      based_on_feature_type(23)
    elsif @type == 'pharmacy_bill_cancelled'
      based_on_feature_type(24)
    elsif @type == 'pharmacy_return'
      based_on_feature_type(25)
    elsif @type == 'optical_bill_creation'
      based_on_feature_type(27)
    elsif @type == 'pharmacy_bill_creation'
      based_on_feature_type(26)
    elsif @type == 'pharmacy_order_placed'
      based_on_feature_type(28)
    end
  end

  def based_on_feature_type(feature_type)
    @cm_events = CommunicationEvent.where(
      feature_type: feature_type,
      organisation_id: @organisation.id,
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
    @communication_in_queue.organisation_id = @organisation.id
    @communication_in_queue.facility_id = @facility.id
    @communication_in_queue.sender_id = @doctor.try(:id)
    @communication_in_queue.sender_role = @doctor.try(:primary_role)
    @communication_in_queue.event_id = @event_id
    @communication_in_queue.event_class = @event_class
    @communication_in_queue.event_name = @type
    @communication_in_queue.recipient_id = @patient.try(:id)
    @communication_in_queue.recipient_name = @patient.try(:fullname)
    @communication_in_queue.recipient_mobilenumber = @patient.try(:whatsappnumber)
    @communication_in_queue.recipient_type = 'patient'
    @communication_in_queue.message_body = @message_body
    @communication_in_queue.is_checked = false
    @communication_in_queue.is_delivered = false
    set_delivery_timestamp
    @communication_in_queue.save
    if @type == 'optical_glass_prescription_advised_store'
      stored_information_in_queue(@communication_in_queue)
      whatsapp_msg_trigger_instantly(cm_event, @communication_in_clone)
    elsif @type == 'pharmacy_store'
      stored_pharmacy_information_in_queue(@communication_in_queue)
      whatsapp_msg_trigger_instantly(cm_event, @communication_in_clone)
    else
      whatsapp_msg_trigger_instantly(cm_event, @communication_in_queue)
    end
  end

  def stored_pharmacy_information_in_queue(communication_in_queue)
    @communication_in_clone = communication_in_queue
    @communication_in_clone.recipient_id = @pharmacy_store.try(:id)
    @communication_in_clone.recipient_name = @pharmacy_store.try(:name)
    @communication_in_clone.recipient_mobilenumber = @pharmacy_store.try(:mobilenumber)
    @communication_in_clone.recipient_type = 'pharmacy_store'
    @communication_in_clone.save
  end

  def stored_information_in_queue(communication_in_queue)
    @communication_in_clone = communication_in_queue
    @communication_in_clone.recipient_id =  @optical_store.try(:id) || @optometrist.try(:id)
    @communication_in_clone.recipient_name = @optical_store.try(:name) || @optometrist.try(:fullname)
    @communication_in_clone.recipient_mobilenumber = @optical_store.try(:mobilenumber) || @optometrist.try(:mobilenumber)
    @communication_in_clone.recipient_type = 'optical_store'
    @communication_in_clone.save
  end

  def set_delivery_timestamp
    @communication_in_queue.deliverydate = Date.current
    @communication_in_queue.deliverytime = Time.current
  end

  def whatsapp_msg_trigger_instantly(cm_event, communication_in_queue)
    @response = CommunicationNotifications::WhatsappNotificationService.call(
      cm_event, communication_in_queue, @organisations_settings
    )
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
      '{APP_TIME}' => @event.try(:start_time).try(:strftime, '%I:%M%p'),
      '{PHARMACY_STORE_NAME}' => (@pharmacy_store.try(:name) || @optometrist.try(:fullname)),
      '{STORE_NAME}' => (@optical_store.try(:name) || @optometrist.try(:fullname)),
      '{OPTICAL_STORE_NAME}' => (@optical_store.try(:name) || @optometrist.try(:fullname)),
      '{STORE_NUMBER}' => (@optical_store.try(:mobilenumber) || @optometrist.try(:mobilenumber) || @pharmacy_store.try(:mobilenumber)) ,
      '{PAT_NUM}' => @patient.try(:mobilenumber),
      '{ORDER_DATE}' => @event.try(:order_date),
      '{EST_DELIVERY_DATE}' => @event.try(:estimated_delivery_date).try(:strftime, '%Y-%m-%d'),
      '{FITTER_NAME}' => @fitter.try(:name),
      '{EST_READY_DATE}' => @event.try(:estimated_ready_date).try(:strftime, '%Y-%m-%d'),
      '{ORDER_ID}' => @event.try(:order_number),
      '{BILL_NUMBER}' => @event.try(:bill_number) || @inventory_invoice.try(:bill_number),
      '{PHARMACY_STORE_ADD}' => "#{@pharmacy_store.try(:address)}, #{@pharmacy_store.try(:city)}, #{@pharmacy_store.try(:state)}, #{@pharmacy_store.try(:pincode)}",
      '{OPTICAL_STORE_ADD}' => "#{@optical_store.try(:address)}, #{@optical_store.try(:city)}, #{@optical_store.try(:state)}, #{@optical_store.try(:pincode)}",
      '{ORDER_DELIVERY_DATE}' => @event.try(:delivery_date).try(:strftime, '%Y-%m-%d')
    }
    re = Regexp.union(map.keys)
    @message_body = communication_event.try(:message_format).gsub(re, map)
  end

  def set_organisation_sms_number
    @organisation.try(:sms_contact_number) || 'XXXXXXXXXX'
  end

  def set_facility_sms_number
    @facility.try(:sms_contact_number) || 'XXXXXXXXXX'
  end

  def get_doctor_setting
    @doctor_settings = @facility_setting
  end
end
