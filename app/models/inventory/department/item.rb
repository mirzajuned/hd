class Inventory::Department::Item
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :department_id, type: String

  field :item_code, type: String
  field :category, type: String
  field :description, type: String
  field :barcode, type: String
  field :manufacturer, type: String
  field :checkoutable, type: Mongoid::Boolean, default: true
  field :stock, type: Integer # All stock of lots combined
  field :vat, type: Float
  field :checkout_count, type: Integer, default: 0
  field :instructions, type: String, default: 'NA'
  field :frequency, type: String, default: 'NA'
  field :duration, type: String, default: 'NA'
  field :central, type: Mongoid::Boolean, default: true

  field :is_deleted, type: Boolean, default: false # for soft delete
  field :in_cart, type: Boolean, default: false # to persist the cart

  belongs_to :facility, class_name: '::Facility'
  belongs_to :organisation, class_name: '::Organisation'
  belongs_to :inventory_item, class_name: '::Inventory::Item'

  # has_many :stocks, class_name: "::Inventory::Department::Item::Stock", dependent: :destroy
  has_many :lots, class_name: '::Inventory::Department::Item::Lot', dependent: :destroy

  # accepts_nested_attributes_for :stocks
  accepts_nested_attributes_for :lots

  def calculate_stock
    lots.where(is_deleted: false).pluck(:stock).inject(&:+)
  end
end
