class Analytics::PatientTypeOverview
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :date, type: Date

  field :patient_type_id, type: BSON::ObjectId
  field :patient_type_count, type: Integer, default: 0
  field :patient_type_label, type: String

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  # for date, week, month year wise data
  field :data_type, type: String  # can be day, week, month, year
  field :start_date, type: Date   # start date
  field :end_date, type: Date     # end date
  field :data_type_range, type: Integer # can be year(2019), can be month number(8), can be week number (32), can be day number (232)
  field :in_year, type: Integer
end
