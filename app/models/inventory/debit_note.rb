class Inventory::DebitNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :amount, type: Float
  field :transaction_date, type: Date
  field :transaction_time, type: Time
  field :flow, type: String
  field :type, type: String
  field :settled_amount, type: Float
  field :pending_amount, type: Float
  field :total_amount, type: Float

  field :user_id, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :user_name, type: String

  embedded_in :inventory_vendor, class_name: '::Inventory::Vendor'
end
