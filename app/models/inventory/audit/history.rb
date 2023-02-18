class Inventory::Audit::History
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :user_id, type: BSON::ObjectId
  field :user_name, type: String

  field :batch_no, type: String
  field :lot_id, type: BSON::ObjectId
  field :variant_id, type: BSON::ObjectId
  field :variant_code, type: String
  field :item_id, type: BSON::ObjectId

  field :transaction_date, type: Date
  field :transaction_time, type: Time
  field :flow, type: String # In/Out

  field :stock_before, type: Float # net stock of lot before transaction, can't be negative
  field :stock_after, type: Float # net stock of lot after transaction, can't be negative

  field :amount_before, type: Float # net amount of lot before transaction, can't be negative
  field :amount_after, type: Float # net amount of lot after transaction, can't be negative

  field :stock_value, type: Float # -ve if transaction_type is out, +ve if transaction_type is in
  field :amount_value, type: Float # -ve if transaction_type is out, +ve if transaction_type is in

  field :transaction_id, type: BSON::ObjectId
  field :transaction_type, type: String # ["Purchase", "Invoice", "Transfer", "Receive", "Purchase Return", "Adjustment", "Return"]
  field :reason, type: String

  field :lot_description, type: String
  field :variant_identifier, type: String
  field :unit_cost, type: Float
  field :list_price, type: Float
  field :custom_field_data, type: Hash, default: {}
  field :model_no, type: String

  # field :invoice_id, type: BSON::ObjectId
  # field :transfer_id, type: BSON::ObjectId
  # field :return_id, type: BSON::ObjectId
  # field :adjustment_id, type: BSON::ObjectId
  #
  field :purchase_order_id, type: BSON::ObjectId

  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :item_name, type: String
  field :bill_number, type: String
  field :lot_identifier, type: String

  field :sub_store_id, type: BSON::ObjectId
  field :sub_store_name, type: String
  
  field :is_migrated, type: Boolean, default: true
  field :tax_amount, type: Float
  field :net_unit_cost_without_tax, type: Float
  field :total_transaction_cost, type: Float

  validates :store_id, presence: true
  validates :sub_store_id, presence: true
  validates :lot_id, presence: true
end
