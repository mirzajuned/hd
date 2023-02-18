class Finance::Expense
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :date, type: DateTime
  field :invoice_id, type: String
  # field :category, type: BSON::ObjectId
  field :contact, type: BSON::ObjectId
  field :category_name, type: String
  field :amount, type: BigDecimal
  field :tax_amount, type: BigDecimal
  field :tax, type: Integer
  field :tax_id, type: BSON::ObjectId
  field :status, type: String # status eg In process/Paid/Unpaid
  field :status_color, type: String # according to the status
  field :payment_mode, type: String
  field :description, type: String
  field :reference, type: String
  field :merchant, type: String
  field :is_deleted, type: Boolean, default: false

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :recorded_by, type: BSON::ObjectId # current user id

  embeds_many :expense_receipts, class_name: '::Finance::ExpenseReceipt'

  accepts_nested_attributes_for :expense_receipts
end
