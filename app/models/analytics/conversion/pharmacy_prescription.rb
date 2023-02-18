class Analytics::Conversion::PharmacyPrescription
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :user_id, type: BSON::ObjectId
  field :role_ids, type: Array, default: []
  field :date, type: Date
  field :facility_id, type: BSON::ObjectId
  field :specialty_id, type: String
  field :organisation_id, type: BSON::ObjectId

  field :total_prescription_advised_count, type: Integer, default: 0
  field :total_prescription_count, type: Integer, default: 0

  field :converted_prescription_count, type: Integer, default: 0 # for doctor how many converted from prescribed by doc

  field :total_prescription_converted_count, type: Integer, default: 0
  field :total_prescription_invoice_amount, type: Float, default: 0.0

  field :total_invoice_amount, type: Integer, default: 0

  field :department_id, type: String

  # analytics_related
  field :data_type, type: String  # can be day, week, month, year
  field :start_date, type: Date   # start date
  field :end_date, type: Date     # end date
  field :data_type_range, type: Integer # can be year(2019), can be month number(8), can be week number (32), can be day number (232)
  field :in_year, type: Integer
end
