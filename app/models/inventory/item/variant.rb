class Inventory::Item::Variant
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  scope :is_active, -> { where(is_deleted: false, is_disabled: false) }
  field :reference_id, type: BSON::ObjectId
  field :description, type: String # name of the item
  field :variant_code, type: String
  field :variant_identifier, type: String

  field :search, type: String
  field :custom_field_tags, type: Array
  field :custom_field_data, type: Hash

  field :stock, type: Float, default: 0 # All stock of lots combined
  field :empty, type: Boolean, default: true # to check out of stock
  field :inventory_capacity, type: Integer, default: 0 # if 0 means no entry  is done, it helps in min item alert.

  field :threshold, type: Integer, default: 30      # in %
  field :threshold_value, type: Integer, default: 0 # in no.
  field :fixed_threshold, type: Boolean, default: false # for fixed threshold value
  field :running_low, type: Boolean, default: true # for running low items
  field :category, type: String

  field :category_id, type: BSON::ObjectId                            # Medication/consumables/opticals etc
  field :sub_category_id, type: BSON::ObjectId                            # Medication/consumables/opticals etc
  field :category_name, type: String
  field :sub_category_name, type: String                            

  field :barcode_present, type: Boolean, default: false # will generate the barcode if selected true
  field :barcode, type: String
  field :barcode_id, type: String
  field :system_generated_barcode, type: Boolean, default: true

  field :level, type: String, default: 'organisation' # store, organisation, etc

  field :item_code, type: String
  field :item_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :is_deleted, type: Boolean, default: false
  field :is_disabled, type: Boolean, default: false

  field :model_no, type: String # Item model number

  field :store_id, type: BSON::ObjectId
  field :department_id, type: String
  field :department_name, type: String
  field :generic_display_name, type: String
  field :generic_display_ids, type: Array, default: []

  field :stockable, type: Boolean, default: true
  field :unit_level, type: Boolean, default: false # To make item at unit level as well

  field :pending_tranfered_quantity, type: Float, default: 0
  field :requested_quantity, type: Float, default: 0
  field :pending_po_quantity, type: Float, default: 0
  field :indent_requested_quantity, type: Float, default: 0
  field :requisition_validation, type: Boolean, default: true
  field :issue_requisition_validation, type: Boolean, default: true
  field :vendor_id, type: BSON::ObjectId
  field :peding_requisition_validation, type: Boolean, default: false # Restict user not to select same variant after creation

  field :integration_identifier, type: BSON::ObjectId # Used for integrating with 3rd Party HIS or other Inventory Solutions to pass item information during API integration.

  field :created_from, type: String
  
  field :is_activated, type: Boolean, default: true # this field will be used to rake purpose

  embeds_many :custom_fields, class_name: '::Inventory::Item::CustomField'
  belongs_to :item, class_name: '::Inventory::Item', optional: true

  has_many :lots, class_name: '::Inventory::Item::Lot', dependent: :destroy

  def calculate_stock
    Inventory::Item::Lot.where(variant_id: id, is_deleted: false).pluck(:stock).inject(&:+)
  end
  validates :description, presence: true
end
