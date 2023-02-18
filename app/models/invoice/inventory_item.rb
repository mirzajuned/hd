class Invoice::InventoryItem
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :item_code, type: String
  field :variant_code, type: String
  field :category, type: String
  field :description, type: String

  field :barcode_present, type: Boolean, default: false # will generate the barcode if selected true
  field :barcode, type: String

  field :item_reference_id, type: BSON::ObjectId
  field :variant_reference_id, type: BSON::ObjectId
  # field :tax_id, type: BSON::ObjectId
  # field :tax_inclusive, type: String

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
  # field :expiry, type: String
  field :expiry_date, type: String
  field :expiry_present, type: Boolean
  field :warranty_expiry, type: Date
  field :quantity, type: Float
  field :condition, type: String
  field :is_deleted, type: Boolean, default: false
  field :empty, type: Boolean, default: false
  field :item_id, type: BSON::ObjectId
  field :lot_id, type: BSON::ObjectId
  field :variant_id, type: BSON::ObjectId
  field :model_no, type: String
  field :lot_unit_ids, type: Array, default: []
  # field :purchase_id, type: BSON::ObjectId

  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :sub_store_id, type: BSON::ObjectId # It will be used for sub store and lot type
  field :sub_store_name, type: String

  # field :item_code, type: String
  # field :category, type: String
  # field :description, type: String
  # field :barcode, type: String
  #
  # field :batch_no, type: String
  #
  # field :price, type: Float
  # field :mark_up, type: Float
  # field :mrp, type: Float
  # field :list_price, type: Float
  # field :vendor, type: String
  # field :manufacturer, type: String
  # field :expiry, type: String
  #
  # field :quantity, type: Integer
  # field :vat, type: Float
  # field :brand, type: String
  # field :color, type: String
  # field :lot_id_hash, type: Hash

  field :tax_group, type: Array, default: []
  field :tax_rate, type: Float
  field :tax_name, type: String
  field :tax_group_id, type: BSON::ObjectId
  field :tax_inclusive, type: Boolean, default: true
  field :unit_non_taxable_amount, type: Float, default: 0.0
  field :unit_taxable_amount, type: Float, default: 0.0
  field :non_taxable_amount, type: Float, default: 0.0
  field :taxable_amount, type: Float, default: 0.0

  # Used for checking whether the item is service. Mostly used in optical invoice where extra services
  # like making charge and fitting charges or delivery charges are added to the invoice
  field :service, type: Mongoid::Boolean, default: false
  field :non_inventory_item, type: Mongoid::Boolean, default: false
  field :billable, type: Mongoid::Boolean, default: true

  field :srn_pending, type: Boolean, default: false
  field :srn_required, type: Boolean, default: false
  field :description_comment, type: String

  field :requisition_pending, type: Boolean, default: false
  field :requisition_required, type: Boolean, default: false

  # belongs_to :inventory_item, class_name: "::Inventory::Department::Item"

  embedded_in :inventory_invoice, class_name: '::Invoice::InventoryInvoice' # Pharmacy checkout
  embedded_in :inventory_order, class_name: '::Invoice::InventoryOrder'

  belongs_to :lot, class_name: '::Inventory::Item::Lot', optional: true

  class << self
    def negative_stock_items
      negative_items = []
      all.each do |item|
        unless item.srn_required
          negative_items << item if item.quantity > item.lot&.stock
        end
      end
      negative_items
      # all.select { |item| item.quantity > item.lot&.stock }
    end
  end
end
