# used
class Inventory::VendorRate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps


  field :is_deleted, type: Boolean, default: false
  field :is_active, type: Boolean, default: true
  field :item_id, type: BSON::ObjectId
  field :item_name, type: String
  field :rate, type: Float
  field :selling_price, type: Float
  field :activity_log, type: Hash, default: {}

  field :variant_id, type: BSON::ObjectId
  field :variant_name, type: String
  field :item_reference_id, type: BSON::ObjectId
  field :variant_reference_id, type: BSON::ObjectId

  field :vendor_id, type: BSON::ObjectId
  field :vendor_group_id, type: BSON::ObjectId
  field :vendor_name, type: String
  field :vendor_group_name, type: String
  field :user_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  belongs_to :variant, class_name: '::Inventory::Item::Variant', optional: true

  default_scope -> { where(is_deleted: false) }

end