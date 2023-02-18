class Inventory::Department::Item::Stock
  include Mongoid::Document
  # include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :price, type: Float
  field :mark_up, type: Float # in percentage
  field :mrp, type: Float
  field :list_price, type: Float
  field :vendor, type: String
  field :manufacturer, type: String
  field :expiry, type: Date
  # field :date_of_entry, type: Date

  belongs_to :item, class_name: '::Inventory::Department::Item'
end
