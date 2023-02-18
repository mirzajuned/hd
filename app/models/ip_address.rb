class IpAddress
include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :remote_ip, type: String
  field :remote_ip_name, type: String
  field :level, type: String
  field :facility_id, type: BSON::ObjectId
  field :facility_name, type: String

  embedded_in :facility, class_name: '::Facility'
  embedded_in :user, class_name: '::User'
end
