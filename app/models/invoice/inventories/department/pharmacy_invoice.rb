class Invoice::Inventories::Department::PharmacyInvoice < Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :bill_number, type: String
  field :recipient, type: String
  field :recipient_mobile, type: String
  field :age, type: Integer
  field :gender, type: String
  field :doctor_name, type: String
  field :doc_reg_no, type: String
  field :patient_id, type: String
  field :patient_identifier, type: String
  field :total_item, type: String
  field :department, type: String
  field :note, type: String
  field :current_department_id, type: String
  field :prescription_id, type: String
  field :net_amount, type: Float
  field :tax_breakup, type: Array, default: []
  field :non_taxable_amount, type: Float, default: 0.0

  field :order_date, type: DateTime
  field :checkout_date, type: DateTime

  field :comments, type: String
  field :mode_of_payment, type: String
  field :store_id, type: BSON::ObjectId
  field :department_id, type: String
  field :department_name, type: String
  field :flag_type, type: String
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  has_many :invoice_returns, class_name: "::Invoice::Inventories::Department::PharmacyReturn"
  field :is_migrated, type: Boolean, default: true

  # Customer Id and Table to be added later
  embeds_many :items, class_name: "::Invoice::Inventories::Item"

  accepts_nested_attributes_for :items, :allow_destroy => true, :reject_if => :all_blank

  scope :newest_first, lambda { order("created_at DESC") }
  scope :ordered_first, lambda { order("order_date DESC") }
  scope :checkout_first, lambda { order("checkout_date DESC") }
end
