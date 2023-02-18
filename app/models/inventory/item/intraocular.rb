class Inventory::Item::Intraocular < Inventory::Item
  include Mongoid::Document

  field :dosage, type: String

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
