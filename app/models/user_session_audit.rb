class UserSessionAudit
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :organisation_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :facility_id, type: BSON::ObjectId
  field :user_name, type: String
  field :user_full_name, type: String
  field :user_id, type: BSON::ObjectId
  field :user_role, type: String
  field :event, type: String
  field :event_by, type: String
  field :event_datetime, type: DateTime
  field :ip_address, type: String
  field :device_name, type: String
  field :device_type, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :zip, type: String
  field :area, type: String
  field :session_id, type: String
end
