class Inventory::Order::History
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :user_id, type: BSON::ObjectId
  field :lot_id, type: BSON::ObjectId
  field :variant_id, type: BSON::ObjectId
  field :item_id, type: BSON::ObjectId

  field :transaction_time, type: Time
  field :transaction_type, type: String # In/Out

  field :stock_before_transaction, type: Integer
  field :stock_after_transaction, type: Integer

  field :entry_type, type: String # Entry, invoice, adjustment, transfer, return
  field :reason, type: String # Entry, invoice, adjustment,

  field :entered_by, type: String
  field :entry_type, type: String # opening_stock, transaction

  field :transaction_id, type: BSON::ObjectId

  field :invoice_id, type: BSON::ObjectId
  field :transaction_id, type: BSON::ObjectId
  field :adjustment_id, type: BSON::ObjectId
end
