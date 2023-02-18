class DashboardSetting
  include Mongoid::Document
  # include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :default_facility, type: BSON::ObjectId
  field :default_user, type: BSON::ObjectId
  field :show, type: Integer
  field :sort, type: String
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
end
