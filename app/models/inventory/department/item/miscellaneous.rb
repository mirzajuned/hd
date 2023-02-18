class Inventory::Department::Item::Miscellaneous < Inventory::Department::Item
  include Mongoid::Document

  field :inventory_capacity, type: Integer
  field :threshold, type: Integer, default: 30
end
