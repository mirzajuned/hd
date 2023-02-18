class Inventory::Item::Optical::Frame < Inventory::Item
  include Mongoid::Document

  field :item_type, type: String, default: 'frame'
  field :brand, type: String
  field :model_no, type: String
  field :color, type: String
  # field :color_code, type: String

  # field :label_color, type: String
  field :reference_no, type: String

  field :pricing_index, type: String # Low, Medium, High
  # field :price, type: Float
  # field :mrp, type: Float
  # field :mark_up, type: Float
  # field :list_price, type: Float

  field :gender, type: String
  # field :temple, type: String
  # field :a, type: String
  # field :b, type: String
  field :frame_type, type: String
  field :frame_material, type: String
  field :inventory_capacity, type: Integer
  # field :threshold, type: Integer #, default: 30

  def self.build_with_custom_field(*_args)
    item = new
    custom_field = [
      { name: 'Gender', value: ['Male', 'Female', 'Unisex'] },
      { name: 'Type', value: ['Rimless', 'Full Rim', 'Semi-Rimless', 'Half-Eye', 'Supra', 'Others'] },
      { name: 'Material', value: ['Shell', 'Metal', 'Titanium', 'Shell(Pediatric Use)', 'Hypo-Allergic Metal', 'TR-90',
                                  'Plastic', 'Carbon', 'Acetate', 'Aluminium', 'Optyl', 'Polyamide', 'Stainless Steel'] }
    ]
    custom_field.each do |cf|
      item.custom_fields.build(cf)
    end
    item
  end
end
