class LinkFacilityDevice
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :qr_auth_token, type: String
  field :device_name, type: String
  field :device_id, type: String
  field :registered_by, type: String
  field :unregistered_by, type: String
  field :last_activity_date, type: DateTime
  field :registered_since, type: DateTime
  field :is_registered, type: Boolean, default: true
  field :is_reregistered, type: Boolean, default: false
  field :unregistered_on, type: DateTime
  field :user_id, type: BSON::ObjectId

  field :organisation_name, type: String
  field :organisation_logo, type: String
  field :country_name, type: String

  validates_uniqueness_of :qr_auth_token, message: 'qr_auth_token already taken'
  validates_presence_of :user_id, message: 'user_id cannot be blank.'
  validates_presence_of :facility_id, message: 'facility_id cannot be blank.'
  validates_presence_of :organisation_id, message: 'organisation_id cannot be blank.'
  validates_presence_of :device_id, message: 'device_id cannot be blank.'
  validates_presence_of :qr_auth_token, message: 'qr_auth_token cannot be blank.'
end
