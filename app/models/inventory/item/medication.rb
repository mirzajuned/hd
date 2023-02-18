class Inventory::Item::Medication < Inventory::Item
  include Mongoid::Document

  field :dosage, type: String
  # field :sub_units, type: Float

  # field :item_type, type: String, default: "Medication"

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
