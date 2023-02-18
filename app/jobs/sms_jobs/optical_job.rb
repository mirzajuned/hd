class OpticalJob < ActiveJob::Base
  queue_as :delayed
  def perform(*args)
    sms_body = args[0]
    mobile = args[1]
    sms_config = YAML.load_file("#{Rails.root}/config/sms_config.yml")
    url = URI.parse("#{sms_config['sms_url']}?username=#{sms_config['username']}&password=#{sms_config['password']}&sender=#{sms_config['sender']}&to=#{mobile}&message=#{sms_body}&reqid=#{sms_config['reqid']}&format=#{sms_config['format']}&route_id=#{sms_config['route_id']}")
    open(url) do |http|
      p response = http.read
    end
  end
end
