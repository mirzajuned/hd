class OtInventoryItem
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :description, type: String
  field :batch_no, type: String
  field :quantity, type: Integer
  field :inventory_item_id, type: String, default: 'non-inventory-item'
  field :invoice_exists, type: Boolean, default: false

  embedded_in :ipdrecord, class_name: "::IpdRecord"
end
