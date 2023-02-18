class Inventory::Item::LotUnit
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :batch_no, type: String
  field :reference_id, type: BSON::ObjectId
  field :description, type: String
  field :self_batched, type: Mongoid::Boolean, default: false
  field :price, type: Float
  field :total_cost, type: Float
  field :unit_cost, type: Float # renamed from price
  field :search, type: String
  field :custom_field_tags, type: Array, default: []
  field :custom_field_data, type: Hash, default: {}
  field :mark_up, type: Float # in percentage
  field :mrp, type: Float
  field :list_price, type: Float
  field :unit_non_taxable_amount, type: Float
  field :unit_taxable_amount, type: Float
  field :tax_rate, type: Float
  field :tax_name, type: String
  field :tax_group_id, type: BSON::ObjectId
  field :tax_inclusive, type: Boolean, default: true
  field :vendor, type: String
  field :vendor_name, type: String
  field :vendor_id, type: BSON::ObjectId
  field :expiry, type: Date
  field :expiry_present, type: Boolean
  field :warranty_expiry, type: Date
  field :stock, type: Integer
  field :is_blocked, type: Boolean, default: false
  field :blocked_stock, type: Integer, default: 0
  field :available_stock, type: Integer, default: ->{ stock }
  field :condition, type: String
  field :transaction_type, type: String # purchase, return, transfer, opening
  field :transaction_id, type: BSON::ObjectId
  field :is_deleted, type: Boolean, default: false
  field :is_disabled, type: Boolean, default: false
  field :empty, type: Boolean, default: false
  field :item_id, type: BSON::ObjectId
  field :item_code, type: String
  field :variant_id, type: BSON::ObjectId
  field :variant_code, type: String
  field :lot_code, type: String
  field :lot_unit_code, type: String
  field :variant_identifier, type: String
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :comment, type: String # for price adjustment
  field :old_lot_id, type: BSON::ObjectId # for tracking old lot
  field :old_lot_ids, type: Array, default: [] # for tracking all old lot ids
  field :category # category of medicine

  field :store_id, type: BSON::ObjectId
  field :department_id, type: String
  field :department_name, type: String

  field :barcode_present, type: Boolean, default: false
  field :barcode, type: String
  field :barcode_id, type: String
  field :system_generated_barcode, type: Boolean, default: false

  field :model_no, type: String # Item model number
  field :generic_display_name, type: String
  field :generic_display_ids, type: Array, default: []

  field :sub_store_name, type: String # sub store name
  field :sub_store_id, type: BSON::ObjectId # sub store id

  field :lot_blocked_id, type: BSON::ObjectId
  field :received_missing_stock, type: Boolean, default: false
  field :missing_stock, type: Float, default: 0

  # Block Lot by user Fields
  field :is_blocked_by_user, type: Boolean, default: false
  # Block Lot by user Fields

  scope :is_active, -> { where(is_deleted: false, is_disabled: false) }

  belongs_to :lot, class_name: '::Inventory::Item::Lot'

  validates :sub_store_id, presence: true
end
