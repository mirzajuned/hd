class Inventory::Item::Lot
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
  field :stock, type: Float
  field :returned_stock, type: Float
  field :is_blocked, type: Boolean, default: false
  field :blocked_stock, type: Float, default: 0
  field :available_stock, type: Float, default: ->{ stock }
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
  field :variant_identifier, type: String
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :comment, type: String # for price adjustment
  field :old_lot_id, type: BSON::ObjectId # for tracking old lot
  field :old_lot_ids, type: Array, default: [] # for tracking all old lot ids
  field :category # category of medicine
  field :category_id # category of medicine

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

  field :stockable, type: Boolean, default: true
  field :sub_store_name, type: String # sub store name
  field :sub_store_id, type: BSON::ObjectId # sub store id
  field :lot_code, type: String # create Unique code for each lot
  field :unit_level, type: Boolean, default: false # To Know current lot has unit level or not

  field :integration_identifier, type: BSON::ObjectId # Used for integrating with 3rd Party HIS or other Inventory Solutions to pass item information during API integration.
  field :purchase_item_id, type: BSON::ObjectId
  field :unit_cost_without_tax, type: Float # Unit Cost without GST
  field :item_discount, type: Float
  field :discount_per_unit,type: Float
  field :net_unit_cost_without_tax, type: Float
  field :pr_net_unit_cost_without_tax, type: Float # this field for purchase return editable
  field :received_missing_stock, type: Boolean, default: false
  field :missing_stock, type: Float, default: 0
  field :margin, type: Float
  field :lot_actual_source, type: String
  field :transaction_date, type: Date
  field :transaction_time, type: Time
  field :transaction_display_id # to display unique id for each transaction

  # Block Lot by user Fields
  field :is_blocked_by_user, type: Boolean, default: false
  field :blocked_by_user, type: BSON::ObjectId
  field :blocked_by_user_name, type: String
  field :blocked_datetime, type: DateTime
  field :blocked_stock_by_user, type: Float, default: 0
  field :blocked_stock_by_user_comment, type: String
  # Block Lot by user Fields

  # this id will be present only in case of requisition through optical order
  field :optical_order_id, type: BSON::ObjectId
  field :requisition_order_id, type: BSON::ObjectId
  field :block_unblock_lots, type: Array, default: []

  # field :tax_amount, type: Float # Tax amount per unit * quantity
  # embeds_many :custom_fields, class_name: '::Inventory::Item::CustomField'
  #
  # accepts_nested_attributes_for :custom_fields,
  #                               reject_if: proc { |attributes| attributes['name'].blank? },
  #                               allow_destroy: true
  #
  # def self.build
  #   item = new
  #   item.custom_fields.build
  #   item
  # end
  # belongs_to :item, class_name: '::Inventory::Item', polymorphic: true

  scope :is_active, -> { where(is_deleted: false, is_disabled: false) }

  has_many :lot_units, class_name: '::Inventory::Item::LotUnit', foreign_key: 'lot_id'
  validates :store_id, presence: true
  validates :sub_store_id, presence: true
  validates :tax_group_id, presence: true
  validates :description, presence: true
end
