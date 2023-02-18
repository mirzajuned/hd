class Inventory::Transaction::Item
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
  field :barcode_id, type: String
  field :system_generated_barcode, type: Boolean, default: false

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
  field :unit_cost, type: Float # renamed from price and this is unit cost with GST
  field :unit_cost_without_tax, type: Float # Unit Cost without GST
  field :item_cost_without_tax, type: Float # Uit cost without GST * quantity
  field :purchase_tax_amount, type: Float # Tax amount per unit * quantity
  field :unit_purchase_tax_amount, type: Float # Tax amount per unit
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
  field :paid_stock, type: Float
  field :stock_blocked, type: Float
  field :stock_package, type: Float, default: 0
  field :stock_subpackage, type: Float, default: 0
  field :stock_unit, type: Float, default: 0
  field :stock_free_unit, type: Float, default: 0
  field :rejected_stock, type: Float, default: 0 #=> using for Inventory::Transaction::Transfer items and Inventory::Transaction::Receive items  
  field :condition, type: String
  field :is_deleted, type: Boolean, default: false
  field :empty, type: Boolean, default: false
  field :item_id, type: BSON::ObjectId
  field :default_variant_id, type: BSON::ObjectId
  field :quantity, type: Float
  field :is_verified, type: Boolean, default: false # it will be used only in case of return right now
  field :initial_stock, type: Float # For OT store
  field :tax_group, type: Array, default: []
  field :total_tax_amount, type: Float
  field :item_amount, type: Float
  field :discount_display_amount, type: Float
  field :lot_unit_ids, type: Array, default: []
  field :received_lot_unit_ids, type: Array, default: []
  field :rejected_lot_unit_ids, type: Array, default: []
  # field :purchase_id, type: BSON::ObjectId

  field :model_no, type: String

  field :order_id, type: BSON::ObjectId # to keeo track of inventory order id
  field :sub_store_id, type: BSON::ObjectId # It will be used for sub store and lot type
  field :sub_store_name, type: String

  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :srn_pending, type: Boolean, default: false
  field :srn_required, type: Boolean, default: false

  field :employee_id, type: BSON::ObjectId
  field :employee_name, type: String
  field :note, type: String
  field :unit_level, type: Boolean, default: false # To Know current item has unit level or not

  field :po_item_id, type: BSON::ObjectId
  field :po_ordered_quantity, type: Float
  field :po_original_ordered_quantity, type: Float

  field :discount, type: Float
  field :item_discount, type: Float
  field :item_discount_type, type: String
  field :discount_per_unit,type: Float
  field :net_unit_cost_without_tax, type: Float
  field :margin, type: Float
  field :amount_after_tax, type: Float
  field :requisition_item_id, type: BSON::ObjectId
  field :received_rejected_stock, type: Boolean, default: false #=> using for Inventory::Transaction::Transfer items
  field :not_received_comment, type: String
  field :item_type, type: String, default: "parent"
  field :item_entry_type, type: String

  # belongs_to :facility, class_name: '::Facility'
  # belongs_to :organisation, class_name: '::Organisation'

  embedded_in :purchase, class_name: '::Inventory::Transaction::Purchase'
  embedded_in :transfer, class_name: '::Inventory::Transaction::Transfer'
  embedded_in :stock_receive, class_name: '::Inventory::Transaction::StockReceive'
  embedded_in :stock_receive_note, class_name: '::Inventory::Transaction::StockReceiveNote'
  embedded_in :stock_opening, class_name: '::Inventory::Transaction::StockOpening'
  embedded_in :direct_stock, class_name: '::Inventory::Transaction::DirectStock'
  embedded_in :store_consumption, class_name: '::Inventory::Transaction::StoreConsumption'

  belongs_to :lot, class_name: '::Inventory::Item::Lot', optional: true
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
  class << self
    def negative_stock_items
      all.select { |item| item.stock > item.lot&.stock }
    end
  end
end
