class Inventory::Item::CustomField
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :value, type: Array, default: []

  embedded_in :item, class_name: '::Inventory::Item'
  embedded_in :variant, class_name: '::Inventory::Item::Variant'
  # embedded_in :lot, class_name: '::Inventory::Item::Lot'
end
