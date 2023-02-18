class Inventory::Department::Item::Consumable < Inventory::Department::Item
  include Mongoid::Document
  field :sub_units, type: Float
  field :inventory_capacity, type: Integer
  field :threshold, type: Integer, default: 30
  field :packaging_type, type: String, default: 'Pack'
end
