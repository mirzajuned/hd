class Analytics::Financial::PaymentMode
  include Mongoid::Document
  include Mongoid::Timestamps

  # Date
  field :date, type: Date

  # Invoice Type { opd: 485396012, ipd: 486546481, pharmacy: 284748001, optical: 50121007 }
  field :type, type: String
  field :type_id, type: String

  # Currency
  field :currency_id, type: BSON::ObjectId
  field :currency_symbol, type: String

  # Payment Mode
  field :cash, type: Float, default: 0.0
  field :card, type: Float, default: 0.0
  field :paytm, type: Float, default: 0.0
  field :google_pay, type: Float, default: 0.0
  field :phonepe, type: Float, default: 0.0
  field :online_transfer, type: Float, default: 0.0
  field :cheque, type: Float, default: 0.0
  field :others, type: Float, default: 0.0

  # Store Details - Future Scope
  field :store_id, type: String
  field :is_store, type: Boolean, default: false

  # Ids
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
end
