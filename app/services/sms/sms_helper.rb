module Sms::SmsHelper
  def check_sms(sms_inq)
    puts "To", sms_inq.recipient_name, sms_inq.recipient_mobilenumber
    puts "-----------------------------------"
    puts sms_inq.message_body
    check_delivery_report(sms_inq)
  end

  def check_delivery_report(sms)
    sms.update(is_checked: true, is_delivered: true)
  end

  def self.included(including_class)
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
end

# Below code is implementation of delivery report api of SANDESHLIVE which is not working
# response = ''
# resp = ''
# url = "http://sandeshlive.in/API/WebSMS/Http/v1.0a/index.php?username=healthg1&password=He1@t4g&sender=HGRAPH&to=7798449191&message=Jane tu ya jane na&reqid=1&format=json&route_id=23"
# url = URI.parse(url)
# open(url) do |http|
#   puts response = http.read
#   puts response.class
#   json_response = JSON.parse(response)
#   message_id = json_response["message"]+json_response["msg_id"]
#   delivery_report_url="http://sandeshlive.in/API/WebSMS/Http/v1.0a/index.php?method=show_dlr&username=healthg1&password=He1@t4g&msg_id=#{message_id}&seq_id=1,2&limit=0,10&format=json"
#   delivery_report_url = URI.parse(delivery_report_url)
#   open(delivery_report_url) do |http|
#     puts resp = http.read
#     puts resp.class
#   end
# end
