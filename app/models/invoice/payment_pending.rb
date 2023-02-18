class Invoice::PaymentPending
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount, type: Float
  field :date, type: Date
  field :received_from, type: BSON::ObjectId
  field :received_from_type, type: String
  field :invoice_type, type: String
  field :payment_pending_breakup_id, type: BSON::ObjectId
  field :is_active, type: Boolean, default: true
  field :is_migrated, type: Boolean, default: true

  field :currency_id, type: BSON::ObjectId
  field :currency_symbol, type: String

  belongs_to :invoice
  belongs_to :facility
  belongs_to :organisation
end
