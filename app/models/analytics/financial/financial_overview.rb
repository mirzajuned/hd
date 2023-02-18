class Analytics::Financial::FinancialOverview
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :date, type: Date
  field :old_patient_count, type: Integer, default: 0
  field :new_patient_count, type: Integer, default: 0
  field :user_id, type: String
  field :opd_new_advance_amount, type: Float, default: 0.0
  field :opd_old_advance_amount, type: Float, default: 0.0
  field :ipd_new_advance_amount, type: Float, default: 0.0
  field :ipd_old_advance_amount, type: Float, default: 0.0
  field :opd_new_advance_count, type: Float, default: 0.0
  field :opd_old_advance_count, type: Float, default: 0.0
  field :ipd_new_advance_count, type: Float, default: 0.0
  field :ipd_old_advance_count, type: Float, default: 0.0
  field :opd_old_patient_amount, type: Float, default: 0.0
  field :opd_new_patient_amount, type: Float, default: 0.0
  field :ipd_old_patient_amount, type: Float, default: 0.0
  field :ipd_new_patient_amount, type: Float, default: 0.0
  field :pharmacy_old_patient_amount, type: Float, default: 0.0
  field :pharmacy_new_patient_amount, type: Float, default: 0.0
  field :optical_old_patient_amount, type: Float, default: 0.0
  field :optical_new_patient_amount, type: Float, default: 0.0
  field :optical_invoice_count, type: Integer, default: 0
  field :pharmacy_invoice_count, type: Integer, default: 0
  field :opd_invoice_count, type: Integer, default: 0
  field :ipd_invoice_count, type: Integer, default: 0
  field :organisation_id, type: String
  field :facility_id, type: String
  field :specialty_id, type: String

  # Currency
  field :currency_id, type: String
  field :currency_symbol, type: String

  # analytics_related
  field :data_type, type: String  # can be day, week, month, year
  field :start_date, type: Date   # start date
  field :end_date, type: Date     # end date
  field :data_type_range, type: Integer # can be year(2019), can be month number(8), can be week number (32), can be day number (232)
  field :in_year, type: Integer
end
