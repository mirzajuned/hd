class Inventory::VendorPurchaseRateHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :variant_id, type: BSON::ObjectId
  field :variant_name, type: String
  field :variant_code, type: String
  field :variant_reference_id, type: BSON::ObjectId
  field :variant_identifier, type: String

  field :purchase_rate, type: Float
  field :paid_quantity, type: Float
  field :free_quantity, type: Float

  field :grn_number, type: String
  field :grn_date_time, type: Time
  field :po_number, type: String
  field :po_date_time, type: Time

  field :category_id, type: BSON::ObjectId
  field :category, type: String
  field :sub_category_id, type: BSON::ObjectId

  field :is_active, type: Boolean, default: true

  field :transaction_item_id, type: BSON::ObjectId

  field :vendor_id, type: BSON::ObjectId
  field :vendor_name, type: String

  field :store_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
end
