class Invoice::Inventories::Department::PharmacyReturn < Invoice
  include Mongoid::Document
  include Mongoid::Timestamps

  field :bill_number, type: String
  field :recipient, type: String
  field :recipient_mobile, type: String
  field :age, type: Integer
  field :gender, type: String
  field :doctor_name, type: String
  field :doc_reg_no, type: String
  field :patient_id, type: String
  field :total_item, type: String
  field :department, type: String
  field :return_amount, type: Float

  belongs_to :facility, class_name: "::Facility"
  belongs_to :organisation, class_name: "::Organisation"
  belongs_to :invoice, class_name: "::Invoice::Inventories::Department::PharmacyInvoice"

  belongs_to :inventory_item, class_name: "::Inventory::Department::Item"

  # Customer Id and Table to be added later
  embeds_many :items, class_name: "::Invoice::Inventories::Item"

  scope :newest_first, lambda { order("created_at DESC") }
end
