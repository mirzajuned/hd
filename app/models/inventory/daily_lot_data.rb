class Inventory::DailyLotData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :lot_id, type: BSON::ObjectId
  field :stock, type: Integer
  field :variant_identifier, type: String
  field :variant_code, type: String
  field :unit_cost, type: Float
  field :list_price, type: Float
  field :description, type: String
  field :batch_no, type: String
  field :stock_in, type: Integer
  field :stock_out, type: Integer
  field :model_no, type: String

  embedded_in :daily_lot_stock, class_name: '::Inventory::DailyLotStock'
end
