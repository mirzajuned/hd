class Inventory::Item::Optical::Other < Inventory::Item
  include Mongoid::Document

  field :item_type, type: String
  field :inventory_capacity, type: Integer
  field :threshold, type: Integer, default: 30

  def self.build_with_custom_field(*_args)
    item = new
    custom_field = []
    custom_field.each do |cf|
      item.custom_fields.build(cf)
    end
    item
  end
end
