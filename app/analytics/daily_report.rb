class DailyReport
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :opd_invoice_transaction, type: Float, default: 0
  field :opd_cash_reg_transaction, type: Float, default: 0
  field :ipd_invoice_transaction, type: Float, default: 0
  field :ipd_cash_reg_transaction, type: Float, default: 0
  field :ins_invoice_transaction, type: Float, default: 0
  field :opd_invoice_ids, type: Array, default: []
  field :ipd_invoice_ids, type: Array, default: []
  field :ins_invoice_ids, type: Array, default: []

  field :opd_tax_collected, type: Float, default: 0.0
  field :ipd_tax_collected, type: Float, default: 0.0

  field :opd_invoice_payment_received, type: Float, default: 0.0
  field :ipd_invoice_payment_received, type: Float, default: 0.0

  field :opd_invoice_payment_pending, type: Float, default: 0.0
  field :ipd_invoice_payment_pending, type: Float, default: 0.0

  field :opd_cr_payment_received, type: Float, default: 0.0
  field :ipd_cr_payment_received, type: Float, default: 0.0

  field :opd_cash_register_ids, type: Array, default: []
  field :ipd_cash_register_ids, type: Array, default: []

  field :currency_id, type: String
  field :currency_symbol, type: String

  field :month, type: Integer
  field :year, type: Integer
  field :date, type: Date

  field :appointment_count, type: Integer, default: 0
  field :admission_count, type: Integer, default: 0
  field :ot_count, type: Integer, default: 0

  field :opd_new_patient_count, type: Integer, default: 0
  field :opd_old_patient_count, type: Integer, default: 0
  field :ipd_new_patient_count, type: Integer, default: 0
  field :ipd_old_patient_count, type: Integer, default: 0

  field :discharge_count, type: Integer, default: 0

  field :admission_ids, type: Array
  field :appointment_ids, type: Array
  field :organisation_id, type: String
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: String
  field :specialty_id, type: String
  field :discharge_count, type: Integer
end
