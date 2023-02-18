class SmsManager
  require 'openssl'
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  
  def initialize
    @sms_config = YAML.load_file("#{Rails.root}/config/sms_config.yml")
  end

  def dispatch_sms(limiter = 5000)
    dispatch_sms = SmsDispatch.includes(:sms_in_queue).where(deliverydate: Date.current, deliverytime: Time.current - 5.minutes..Time.current, :delivery_status.ne => 'Delivered', is_deleted: false, :third_party_msg_id.in => [nil, '']).limit(limiter)
    dispatch_sms.each do |sms|
      begin
        send_sms(sms)
        LoggerService.new.integration(sms, 'sms_success', "sms_success=======================>")
      rescue StandardError
        LoggerService.new.integration(sms, 'sms_error', "sms_error==========================>")
      end
    end
  end

  def send_sms(sms)
    response = ''
    recipient_id = sms.sms_in_queue.recipient_id
    sender_id = sms.sms_in_queue.sender_id
    recipient_name = sms.sms_in_queue.recipient_name
    sender_role = sms.sms_in_queue.sender_role
    event_name = sms.sms_in_queue.event_name
    request_data_hash = { 'sms_dispatch_id': sms.id.to_s, 'third_party_msg_id': sms.third_party_msg_id, 'deliverydate': sms.deliverydate, 'deliverytime': sms.deliverytime, 'delivery_status': sms.delivery_status, 'is_deleted': sms.is_deleted, 'recipient_id': recipient_id, 'recipient_name': recipient_name, 'sender_id': sender_id, 'sender_role': sender_role, 'event_name': event_name, 'mobilenumber': sms.mobilenumber }
    url = URI.parse("#{@sms_config['sms_url']}?userid=#{@sms_config['userid']}&password=#{@sms_config['password']}&sender=#{@sms_config['sender']}&to=#{sms.mobilenumber}&message=#{sms.sms_body}&reqid=#{@sms_config['reqid']}&format=#{@sms_config['format']}&route_id=#{@sms_config['route_id']}&unique=#{@sms_config['unique']}")
    
    ApiIntegration::DataRequests::CreateService.call(request_data_hash, url, 'dispatched', nil, nil, {})

      URI.open(url) do |http|
        response = http.read
        # puts used intentionally
      end

      if response.present?
        response = JSON.parse(response)
        sms.update(third_party_msg_id: response['msg_id'], delivery_status: 'Delivered', linecount: response['seq_id']['linecount'], billcredit: response['billcredit'], extra_info: response["seq_id"])
      else
        response = {
            delivery_status: 'Not Delivered', 'extra_info': 'Response not present'
        }
      end
      response_data_hash = {
          'sms_dispatch_id': sms.id.to_s, 'response' => response, 'recipient_id': recipient_id,
          'recipient_name': recipient_name, 'sender_id': sender_id, 'sender_role': sender_role, 'event_name': event_name
      }

      ApiIntegration::DataResponses::CreateService.call(response_data_hash, url, 'sent', nil, nil, {})

    # url = @sms_config['sms_url']
    # payload = {
    #             userid: @sms_config['userid'], password: @sms_config['password'],
    #             sender: @sms_config['sender'], to: sms.mobilenumber, message: "#{sms.sms_body} HGRAPH",
    #             reqid: @sms_config['reqid'], format: @sms_config['format'],
    #             route_id: @sms_config['route_id'], unique: @sms_config['unique']
    #           }
    # response = RestClient::Request.execute(method: :get, url: url, payload: payload.to_json)
  end

  def add_delivery_report(msg_id, linecount, sms)
    if msg_id.present?
      url = "#{@sms_config['sms_url']}?method=show_dlr&userid=#{@sms_config['userid']}&password=#{@sms_config['password']}&msg_id=#{msg_id}&seq_id=1&limit=1&format=#{@sms_config['format']}"
      delivery_report = ''
      url = URI.parse(url)
      open(url) do |http|
        delivery_report = http.read
      end
      json_delivery_report = JSON.parse(delivery_report)

      if json_delivery_report["1"]["status"].present?
        sms.update(linecount: linecount, billcredit: json_delivery_report["1"]["billcredit"], sendondate: json_delivery_report["1"]['sendondate'], delivery_status: json_delivery_report["1"]["status"])

        if sms.sms_in_queue
          sms.sms_in_queue.update(third_party_msg_id: sms.third_party_msg_id, linecount: json_delivery_report['linecount'], billcredit: json_delivery_report["1"]["billcredit"], sendondate: json_delivery_report["1"]['sendondate'], delivery_status: json_delivery_report["1"]["status"], extra_info: sms.extra_info)
        end
      else
        sms.update(third_party_msg_id: json_delivery_report['msg_id'], linecount: json_delivery_report['linecount'], delivery_status: "Pending")
      end
      clear_dispatch_list(sms)
    end
  end

  def clear_dispatch_list(sms)
    if sms.delivery_status == "Delivered" || sms.resend_count == 5
      sms.destroy
    else
      update_delivery_date(sms)
    end
  end

  def update_delivery_date(sms)
    delivery_time_date = sms.deliverytime.to_date
    @delivery_date = sms.deliverydate
    if delivery_time_date < (@delivery_date + 1.hours).to_date
      @delivery_date = @delivery_date + 1.hours
      resend_count = sms.resend_count + 1
      sms.update(delivery_status: "pending/error", resend_count: resend_count, deliverydate: @delivery_date, deliverytime: sms.deliverytime + 1.hours)
    end
  end
end
