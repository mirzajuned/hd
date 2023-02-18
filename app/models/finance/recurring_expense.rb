class Finance::RecurringExpense
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :date, type: DateTime
  field :contact, type: BSON::ObjectId
  field :category_name, type: String

  field :profile_name, type: String
  field :repetition, type: String # week, month, year
  field :starts_on, type: Date
  field :ends_on, type: Date
  field :expiration, type: Boolean # if no then ends_on will be empty.
  field :recurring_status, type: Boolean, default: true # Active/ Inactive
  field :last_expense_date, type: Date
  field :next_expense_date, type: Date

  field :note, type: String

  # field :date, type: Date
  field :merchant, type: String
  # field :category, type: String

  field :contact, type: BSON::ObjectId
  field :category_name, type: String

  field :amount, type: BigDecimal
  field :tax_amount, type: BigDecimal
  field :tax, type: Integer
  field :tax_id, type: BSON::ObjectId

  field :color, type: Integer # according to the status

  # field :payment_mode, type: String
  field :description, type: String
  field :reference, type: String

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :recorded_by, type: BSON::ObjectId # current user id

  # belongs_to :organisation,index: {background: true}
end
