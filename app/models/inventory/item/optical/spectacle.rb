class Inventory::Item::Optical::Spectacle < Inventory::Item
  include Mongoid::Document

  field :item_type, type: String, default: 'spectacle'
  field :brand, type: String
  field :contact_type, type: String
  field :material, type: String
  field :wearing_period, type: String # daily, extended
  field :color, type: String
  field :model_no, type: String

  field :replacement, type: String # monthly, quarterly

  field :pricing_index, type: String # Low, Medium, High
  # field :price, type: Float
  # field :mrp, type: Float
  # field :mark_up, type: Float
  # field :list_price, type: Float

  field :gender, type: String
  field :power, type: String

  field :inventory_capacity, type: Integer
  # field :threshold, type: Integer #, default: 30

  def self.build_with_custom_field(*_args)
    item = new
    custom_field = []
    custom_field.each do |cf|
      item.custom_fields.build(cf)
    end
    item
  end
end
