class Inventory::Department::Item::Medication < Inventory::Department::Item
  include Mongoid::Document

  field :dosage, type: String
  field :sub_units, type: Float
  field :dispensing_unit, type: String
  field :inventory_capacity, type: Integer
  field :threshold, type: Integer, default: 30
  field :packaging_type, type: String, default: 'Pack'
  field :measurement_unit, type: String
end
