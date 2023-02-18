class UserMobileDevice
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :device_id, type: String
  # field :device_type, type: String
  # field :device_os, type: String

  belongs_to :user
  belongs_to :organisation
end
