class Invoice::Inventories::Department::OpticalInvoice < Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :bill_number, type: String
  field :recipient, type: String
  field :recipient_mobile, type: String
  field :recipient_email, type: String
  field :age, type: Integer
  field :gender, type: String
  field :doctor_name, type: String
  field :doc_reg_no, type: String
  field :patient_id, type: String
  field :patient_identifier, type: String
  field :total_item, type: String
  field :department, type: String
  field :delivery_date, type: Date
  field :note, type: String
  field :current_department_id, type: String
  field :notify, type: Boolean, default: false
  field :notify_type, type: String
  field :notified, type: Boolean, default: false
  field :called, type: Boolean, default: false
  field :sms, type: String
  field :email, type: String
  field :payment_completed, type: Boolean, default: false
  field :advance_taken, type: Boolean, default: false
  field :prescription_id, type: String
  field :comments, type: String
  field :tax_breakup, type: Array, default: []
  field :non_taxable_amount, type: Float, default: 0.0
  field :net_amount, type: Float
  field :order_date, type: DateTime
  field :checkout_date, type: DateTime
  field :is_migrated, type: Boolean, default: true
  field :store_id, type: BSON::ObjectId
  field :department_id, type: String
  field :flag_type, type: String
  field :department_name, type: String
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  has_many :invoice_returns, class_name: "::Invoice::Inventories::Department::OpticalReturn"

  # Customer Id and Table to be added later
  embeds_many :items, class_name: "::Invoice::Inventories::Item"
  accepts_nested_attributes_for :items, :allow_destroy => true, :reject_if => :all_blank

  scope :newest_first, lambda { order("created_at DESC") }
  scope :ordered_first, lambda { order("order_date DESC") }
  scope :checkout_first, lambda { order("checkout_date DESC") }
end
