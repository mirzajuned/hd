class Inventory::Department::Item::Optical::Frame < Inventory::Department::Item
  include Mongoid::Document

  field :item_type, type: String
  field :brand, type: String
  field :model_no, type: String
  field :color, type: String
  field :color_code, type: String

  field :label_color, type: String
  field :reference_no, type: String

  field :pricing_index, type: String # Low, Medium, High
  # field :price, type: Float
  # field :mrp, type: Float
  # field :mark_up, type: Float
  # field :list_price, type: Float

  field :gender, type: String
  # field :temple, type: String
  # field :a, type: String
  # field :b, type: String

  field :frame_type, type: String
  field :frame_material, type: String
  # field :inventory_capacity, type: Integer
  # field :threshold, type: Integer #, default: 30
end
