class Inventory::CheckoutLog::Item
  include Mongoid::Document
  # include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :item_code, type: String
  field :category, type: String
  field :description, type: String
  field :barcode, type: String

  field :batch_no, type: String

  field :price, type: Float
  field :mark_up, type: Float
  field :mrp, type: Float
  field :list_price, type: Float
  field :vendor, type: String
  field :manufacturer, type: String
  field :expiry, type: String

  field :is_deleted, type: Boolean, default: false # for soft delete
  field :in_cart, type: Boolean, default: false # to persist the cart

  field :quantity, type: Integer

  embedded_in 'checkoutlog', class_name: '::Inventory::CheckoutLog'
end
