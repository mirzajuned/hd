class Inventory::Department::Item::Lot
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :batch_no, type: String
  field :self_batched, type: Mongoid::Boolean, default: false
  field :price, type: Float
  field :mark_up, type: Float # in percentage
  field :mrp, type: Float
  field :list_price, type: Float

  field :vendor, type: String
  # field :manufacturer, type: String

  field :expiry, type: Date
  field :warranty_expiry, type: Date

  field :is_deleted, type: Boolean, default: false

  field :stock, type: Integer
  field :empty, type: Mongoid::Boolean, default: false

  field :is_deleted, type: Boolean, default: false # for soft delete

  belongs_to :item, class_name: '::Inventory::Department::Item'
end
