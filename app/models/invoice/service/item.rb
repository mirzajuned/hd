class Invoice::Service::Item
  include Mongoid::Document
  include Mongoid::Timestamps

  field :item_code, type: String
  field :description, type: String
  field :unit_price, type: Float
  field :quantity, type: Integer
  field :price, type: Float
  field :item_entry_date, type: Time
  field :patient_payed, type: String

  field :tax_group_id, type: BSON::ObjectId
  field :tax_inclusive, type: Boolean, default: false
  field :non_taxable_amount, type: Float, default: 0
  field :taxable_amount, type: Float, default: 0
  field :tax_group, type: Array, default: []
  # InvoiceItemCardId
  field :invoice_item_card_id, type: String

  embedded_in :service, class_name: "::Invoice::Service"
end
