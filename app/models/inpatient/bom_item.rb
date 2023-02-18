class Inpatient::BomItem
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  field :item_code, type: String
  field :variant_code, type: String
  field :category, type: String
  field :description, type: String

  field :barcode_present, type: Boolean, default: false # will generate the barcode if selected true
  field :barcode, type: String

  field :item_reference_id, type: BSON::ObjectId
  field :variant_reference_id, type: BSON::ObjectId

  field :batch_no, type: String
  field :self_batched, type: Mongoid::Boolean, default: false
  field :total_cost, type: Float
  field :unit_cost, type: Float # renamed from price
  field :search, type: String
  field :variant_identifier, type: String
  field :custom_field_tags, type: Array, default: []
  field :custom_field_data, type: Hash
  field :mark_up, type: Float # in percentage
  field :mrp, type: Float
  field :list_price, type: Float
  field :total_list_price, type: Float
  field :vendor, type: String
  field :expiry, type: Date
  field :expiry_date, type: String
  field :expiry_present, type: Boolean
  field :warranty_expiry, type: Date
  field :quantity, type: Float
  field :condition, type: String
  field :is_deleted, type: Boolean, default: false
  field :empty, type: Boolean, default: false
  field :item_id, type: BSON::ObjectId
  field :variant_id, type: BSON::ObjectId
  field :bom_list_price, type: Float
  field :bom_quantity, type: Float
  field :tray_id, type: BSON::ObjectId
  field :tray_item_id, type: BSON::ObjectId
  field :billable, type: Boolean, default: false
  field :lot_id, type: String

  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :tax_group, type: Array, default: []
  field :tax_rate, type: Float
  field :tax_name, type: String
  field :tax_group_id, type: BSON::ObjectId
  field :tax_inclusive, type: Boolean, default: true
  field :unit_non_taxable_amount, type: Float, default: 0.0
  field :unit_taxable_amount, type: Float, default: 0.0
  field :non_taxable_amount, type: Float, default: 0.0
  field :taxable_amount, type: Float, default: 0.0

  field :service, type: Mongoid::Boolean, default: false
  field :non_inventory_item, type: Mongoid::Boolean, default: false

  embedded_in :bill_of_material, class_name: '::Inpatient::BillOfMaterial'
end
