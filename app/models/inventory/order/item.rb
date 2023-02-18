class Inventory::Order::Item
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  field :item_code, type: String
  field :variant_code, type: String
  field :category, type: String
  field :category_id, type: BSON::ObjectId
  field :description, type: String
  field :remark, type: String

  field :barcode_present, type: Boolean, default: false # will generate the barcode if selected true
  field :barcode, type: String

  field :item_reference_id, type: BSON::ObjectId
  field :variant_reference_id, type: BSON::ObjectId
  field :lot_reference_id, type: BSON::ObjectId
  field :tax_rate, type: Float
  field :tax_name, type: String
  field :tax_group_id, type: BSON::ObjectId
  field :tax_inclusive, type: Boolean, default: true

  field :batch_no, type: String
  field :self_batched, type: Mongoid::Boolean, default: false
  field :total_cost, type: Float
  field :amount_after_tax, type: Float
  field :unit_cost, type: Float # renamed from price and this is unit cost with GST
  field :unit_cost_without_tax, type: Float # Unit Cost without GST
  field :item_cost_without_tax, type: Float # Uit cost without GST * quantity
  field :unit_purchase_tax_amount, type: Float # Tax amount per unit
  field :purchase_tax_amount, type: Float # Tax amount per unit * quantity
  field :search, type: String
  field :variant_identifier, type: String
  field :custom_field_tags, type: Array, default: []
  field :custom_field_data, type: Hash, default: {}
  field :custom_field, type: Hash, default: {}
  field :mark_up, type: Float # in percentage
  field :mrp, type: Float
  field :list_price, type: Float
  field :unit_non_taxable_amount, type: Float
  field :unit_taxable_amount, type: Float
  field :vendor, type: String
  field :vendor_name, type: String
  field :vendor_id, type: BSON::ObjectId
  field :expiry, type: Date
  field :expiry_present, type: Boolean
  field :warranty_expiry, type: Date
  field :stock, type: Float # this is paid + free
  field :stock_blocked, type: Float
  field :stock_received, type: Float, default: 0
  field :stock_paid_blocked, type: Float
  field :stock_paid_received, type: Float, default: 0
  field :stock_free_blocked, type: Float
  field :stock_free_received, type: Float, default: 0
  field :stock_package, type: Float, default: 0
  field :stock_subpackage, type: Float, default: 0
  field :stock_unit, type: Float, default: 0
  field :stock_free_unit, type: Float, default: 0
  field :condition, type: String
  field :is_deleted, type: Boolean, default: false
  field :stock_received_status, type: Boolean, default: false
  field :empty, type: Boolean, default: false
  field :item_id, type: BSON::ObjectId
  field :default_variant_id, type: BSON::ObjectId
  field :quantity, type: Float
  field :is_verified, type: Boolean, default: false # it will be used only in case of return right now
  field :tax_group, type: Array, default: []
  field :lot_unit_ids, type: Array, default: []
  # field :purchase_id, type: BSON::ObjectId

  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :model_no, type: String
  field :pending_tranfered_quantity, type: Float
  field :requested_quantity, type: Float
  field :requisition_validation, type: Boolean, default: true
  field :sub_store_id, type: BSON::ObjectId # It will be used for sub store and lot type
  field :sub_store_name, type: String
  field :remarks, type: String
  field :currency_symbol, type: String
  field :currency_id, type: BSON::ObjectId
  field :paid_stock, type: Float, default: 0
  field :item_discount, type: Float
  field :item_discount_type, type: String
  field :item_discount_percent, type: Float
  field :discount_per_unit,type: Float
  field :requisition_item_id, type: BSON::ObjectId
  field :received_requested_stock, type: Float, default: 0
  field :dispensing_unit, type: String

  field :indent_item_id, type: BSON::ObjectId
  field :indent_ordered_quantity, type: Float
  field :indent_original_ordered_quantity, type: Float
  field :indent_remaining_quantity, type: Float

  field :indent_remarks, type: String
  field :item_units, type: Integer
  # belongs_to :facility, class_name: '::Facility'
  # belongs_to :organisation, class_name: '::Organisation'

  embedded_in :order, class_name: '::Inventory::Order::Purchase'

  # embeds_many :custom_fields, class_name: '::Inventory::Item::CustomField'
  # accepts_nested_attributes_for :custom_fields,
  #                               reject_if: proc { |attributes| attributes['name'].blank? },
  #                               allow_destroy: true

  #
  # def self.build
  #   item = new
  #   item.custom_fields.build
  #   item
  # end
  # belongs_to :item, class_name: "::Inventory::Item", polymorphic: true
end
