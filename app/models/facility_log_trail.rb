class FacilityLogTrail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :action_taken, type: String
  field :user_role, type: String
  field :user_name, type: String
  field :ip_address, type: String
  field :user_id, type: BSON::ObjectId
  field :time, type: Time, default: Time.current

  field :changes_field, type: Hash, default: {}

  embedded_in :facility, class_name: '::Facility'
end
