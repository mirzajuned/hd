# used
class Inventory::RolRule
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps


  field :is_deleted, type: Boolean, default: false
  field :is_active, type: Boolean, default: true
  field :item_id, type: BSON::ObjectId
  field :item_name, type: String
  field :max_value, type: Integer
  field :min_value, type: Integer
  field :rol_value, type: Integer
  field :activity_log, type: Array, default: []

  field :variant_id, type: BSON::ObjectId
  field :variant_name, type: String
  field :item_reference_id, type: BSON::ObjectId
  field :variant_reference_id, type: BSON::ObjectId

  field :store_id, type: BSON::ObjectId
  field :store_name, type: String
  field :user_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId


  default_scope -> { where(is_deleted: false) }

  validates_presence_of :rol_value, :max_value

end