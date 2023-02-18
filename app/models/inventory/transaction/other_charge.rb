class Inventory::Transaction::OtherCharge
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :other_charge_id, type: BSON::ObjectId
  field :name, type: String
  field :amount, type: String
  field :percent, type: Float
  field :net_amount, type: BSON::ObjectId

  embedded_in :stock_receive_note, class_name: '::Inventory::Transaction::StockReceiveNote'
  embedded_in :purchase, class_name: '::Inventory::Transaction::Purchase'
  embedded_in :purchase, class_name: '::Inventory::Order::Purchase'
end
