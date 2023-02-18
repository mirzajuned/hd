class Inventory::Item::Asset < Inventory::Item
  include Mongoid::Document

  field :batch_no, type: String
  field :price, type: Float
  field :vendor, type: String
  field :expiry, type: Date
  field :warranty_expiry, type: Date
  field :manufacturer, type: String
  field :maintained_on, type: Date
  field :maintainance_due, type: Date
  field :condition, type: String
  # field :inventory_capacity, type: Integer
  #  field :threshold, type: Integer

  def self.build(*args)
    item = new
    custom_field = args[0]
    if custom_field.present?
      custom_field.each do |cf|
        item.custom_fields.build(cf)
      end
    else
      item.custom_fields.build
    end
    item
  end
end
