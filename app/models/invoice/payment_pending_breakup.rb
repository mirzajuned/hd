class Invoice::PaymentPendingBreakup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount, type: Float
  field :received_from, type: BSON::ObjectId

  field :currency_id, type: BSON::ObjectId
  field :currency_symbol, type: String

  field :date, type: Date
  field :time, type: Time

  field :is_canceled, type: Boolean, default: false
  field :cancel_date, type: Date
  field :cancel_time, type: Time

  embedded_in :invoice
  embedded_in :finance_report_data, class_name: '::Finance::ReportData'
end
