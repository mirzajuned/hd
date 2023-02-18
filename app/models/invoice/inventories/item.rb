class Invoice::Inventories::Item
  include Mongoid::Document

  field :item_code, type: String
  field :category, type: String
  field :description, type: String
  field :barcode, type: String

  field :batch_no, type: String

  field :price, type: Float
  field :mark_up, type: Float
  field :mrp, type: Float
  field :list_price, type: Float
  field :vendor, type: String
  field :manufacturer, type: String
  field :expiry, type: String
  field :expiry_date, type: String
  field :total_list_price, type: Float

  field :quantity, type: Integer
  field :vat, type: Float
  field :brand, type: String
  field :color, type: String
  field :lot_id_hash, type: Hash

  field :tax_group, type: Array, default: []
  field :tax_group_id, type: BSON::ObjectId
  field :tax_inclusive, type: Boolean, default: true
  field :non_taxable_amount, type: Float, default: 0.0
  field :taxable_amount, type: Float, default: 0.0

  # Used for checking whether the item is service. Mostly used in optical invoice where extra services
  # like making charge and fitting charges or delivery charges are added to the invoice
  field :service, type: Mongoid::Boolean, default: false
  field :non_inventory_item, type: Mongoid::Boolean, default: false
  field :billable, type: Mongoid::Boolean, default: true

  belongs_to :inventory_item, class_name: "::Inventory::Department::Item"

  embedded_in :pharmacy_log, class_name: "::Invoice::Inventories::Deparment::PharmacyInvoice" # Pharmacy checkout
  embedded_in :deparment_log, class_name: "::Invoice::Inventories::DeparmentInvoice" # Deparment checkout (intrahospital)
  embedded_in :optical_log, class_name: "::Invoice::Inventories::Deparment::OpticalInvoice" # Optical checkout (intrahospital)
end
