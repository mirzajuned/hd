class UserLogin
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :login_time, type: Time
  field :remote_ip, type: String
  field :user_fullname, type: String
  field :facility_name, type: String

  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :logout_time, type: Time
  field :auto_logout_time, type: Time, default: Date.current + 1 + 4.hours
  field :is_logged_out, type: Boolean, default: false

  # fields releated to IP Adress details

  # field :continent, type: String
  # field :continent_code, type: String
  # field :country, type: String
  # field :country_code, type: String
  # field :country_calling_code, type: String
  # field :region, type: String
  # field :region_name, type: String
  # field :region_code, type: String
  # field :city, type: String
  # field :district, type: String
  # field :zip, type: String
  # field :latitude, type: String
  # field :longitude, type: String
  # field :time_zone, type: String
  # field :utc_offset, type: String
  # field :currency, type: String
  # field :currency_name, type: String
  # field :isp, type: String
  # field :org, type: String
  # field :proxy, type: Boolean
  # field :platform, type: String
  # field :browser, type: String
  # field :user_agent, type: String
  # field :screen_size, type: String
end
