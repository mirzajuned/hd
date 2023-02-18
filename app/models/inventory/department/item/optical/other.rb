class Inventory::Department::Item::Optical::Other < Inventory::Department::Item
  include Mongoid::Document

  field :item_type, type: String
  field :inventory_capacity, type: Integer
  field :threshold, type: Integer, default: 30
end
