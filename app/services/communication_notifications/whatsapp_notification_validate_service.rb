class CommunicationNotifications::WhatsappNotificationValidateService

  def self.call(phone_number=nil, organisations_settings=nil)
    @whatsapp_config = YAML.load_file("#{Rails.root}/config/whatsapp_config.yml")
    @phone_number = phone_number
    @organisations_settings = organisations_settings
    send_whatsapp_notification
  end

  def self.send_whatsapp_notification
    @account_sid = @organisations_settings.try(:organisation_account_sid) if @organisations_settings
    unless @account_sid.present?
      @account_sid = @whatsapp_config['account_sid']
    end
    payload = { 'msgBody': 'validation check', 'to': '+916362541550', 'accountSid': @account_sid }
    begin
      request = RestClient::Request.execute(method: :post, url: @whatsapp_config['whatsapp_url'],
                                              user: @whatsapp_config['username'],
                                              password: @whatsapp_config['password'],
                                              payload: payload,
                                              headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
      @response = JSON.parse(request)['message']
    rescue StandardError
      @status = 'Failed'
      @status_code = 500
      @message = 'No Response Received'
    end
  end
end
