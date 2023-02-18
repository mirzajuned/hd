class CommunicationNotifications::WhatsappNotificationService

  def self.call(communication_event = nil, communication_in_queue, organisation_settings)
    @whatsapp_config = YAML.load_file("#{Rails.root}/config/whatsapp_config.yml")
    @communication_event = communication_event
    @communication_in_queue = communication_in_queue
    @organisations_settings = organisation_settings if organisation_settings.present?
    @organisations_settings = @communication_in_queue.try(:organisation).try(:organisations_setting) if organisation_settings.nil?
    send_whatsapp_notification
  end

  def self.send_whatsapp_notification
    @account_sid = @organisations_settings.try(:organisation_account_sid) if @organisations_settings
    unless @account_sid.present?
      @account_sid = @whatsapp_config['account_sid']
    end
    payload = { 'msgBody': @communication_in_queue.message_body, 'to': '+916362541550', 'accountSid': @account_sid }
    begin
      request = RestClient::Request.execute(method: :post, url: @whatsapp_config['whatsapp_url'],
                                              user: @whatsapp_config['username'],
                                              password: @whatsapp_config['password'],
                                              payload: payload,
                                              headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
      @response = JSON.parse(request)['message']
      update_communication_in_queue_delivery_status('Done')
    rescue StandardError
      @status = 'Failed'
      @status_code = 500
      @message = 'No Response Received'
      update_communication_in_queue_delivery_status('Failed')
    end
  end

  def self.update_communication_in_queue_delivery_status(delivery_status)
    @communication_in_queue.delivery_status = delivery_status
    @communication_in_queue.is_delivered = true
    @communication_in_queue.save
  end
end
