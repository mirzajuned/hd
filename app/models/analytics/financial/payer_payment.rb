class Analytics::Financial::PayerPayment
  include Mongoid::Document
  include Mongoid::Timestamps

  # Date
  field :date, type: Date

  # Contact Info
  field :payer_master_id, type: BSON::ObjectId
  field :contact_id, type: BSON::ObjectId
  field :contact_name, type: String

  # Currency
  field :currency_id, type: BSON::ObjectId
  field :currency_symbol, type: String

  # Received
  field :received_opd_total, type: Float, default: 0.0
  field :received_ipd_total, type: Float, default: 0.0
  field :received_total, type: Float, default: 0.0

  # Pending
  field :pending_opd_total, type: Float, default: 0.0
  field :pending_ipd_total, type: Float, default: 0.0
  field :pending_total, type: Float, default: 0.0

  # Overall
  field :opd_total, type: Float, default: 0.0
  field :ipd_total, type: Float, default: 0.0
  field :total, type: Float, default: 0.0

  # Ids
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
end
