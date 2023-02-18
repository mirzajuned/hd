class Invoice::AdvancePaymentBreakup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :advance_payment_id, type: BSON::ObjectId
  field :advance_display_id, type: String
  field :reason, type: String
  field :mode_of_payment, type: String
  field :advance_date, type: Date
  field :advance_time, type: DateTime
  field :date, type: Date
  field :time, type: DateTime
  field :advance_amount, type: Float
  field :amount, type: Float

  field :currency_id, type: BSON::ObjectId
  field :currency_symbol, type: String

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
  field :user_id, type: BSON::ObjectId

  embedded_in :invoice
  embedded_in :finance_report_data, class_name: '::Finance::ReportData'
end
