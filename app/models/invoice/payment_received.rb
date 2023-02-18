class Invoice::PaymentReceived
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount, type: Float
  field :date, type: Date
  field :time, type: Time
  field :received_by, type: BSON::ObjectId
  field :received_from, type: BSON::ObjectId
  field :received_from_type, type: String
  field :invoice_type, type: String
  field :mode_of_payment, type: String
  field :cash, type: Float
  field :card, type: Float
  field :card_number, type: Integer
  field :card_transaction_note, type: String
  field :paytm_transaction_id, type: String
  field :paytm_transaction_note, type: String
  field :gpay_transaction_id, type: String
  field :gpay_transaction_note, type: String
  field :phonepe_transaction_id, type: String
  field :phonepe_transaction_note, type: String
  field :transfer_date, type: String # for Online transfer
  field :transfer_note, type: String # for Online transfer
  field :cheque_date, type: String
  field :cheque_note, type: String
  field :other_transaction_id, type: String
  field :other_note, type: String
  field :payment_received_breakup_id, type: BSON::ObjectId
  field :is_active, type: Boolean, default: true
  field :is_migrated, type: Boolean, default: true

  field :currency_id, type: BSON::ObjectId
  field :currency_symbol, type: String

  belongs_to :invoice
  belongs_to :facility
  belongs_to :organisation
end
