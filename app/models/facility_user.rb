class FacilityUser
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :sms_feature, type: Hash
  field :opd_print_setting, type: Hash
  field :ipd_print_setting, type: Hash
  field :is_active, type: Boolean, default: true
  field :facility_id, type: BSON::ObjectId
  field :facility_setting_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :user_name, type: String
  field :role_ids, type: Array
  index({ facility_id: 1, user_id: 1 }, { background: true })
end
