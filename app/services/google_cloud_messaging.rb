require 'gcm'

class GoogleCloudMessaging
  def self.register_device(options = {})
    user_mob_device = UserMobileDevice.new(:user_id => options[:user_id], :organisation_id => options[:organisation_id], :device_id => options[:device_id])
    if user_mob_device.save()
      return true
    else
      return false
    end
  end

  def self.unregister_device(options = {})
  end

  def self.update_device(options = {})
  end

  def self.send_message(options = {}, organisation_id)
    gcm = GCM.new("#{Global.gcm.projectid}")
    reg_device_ids = UserMobileDevice.where(:organisation_id => organisation_id).device_id
    options = { data: options }
    response = gcm.send(reg_device_ids, options)
    # fname = "/home/max/ehrapp/gcmsample.txt"
    # somefile = File.open(fname, "a")
    # somefile.puts options
    # somefile.close
  end
end
