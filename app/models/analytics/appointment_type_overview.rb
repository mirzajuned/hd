class Analytics::AppointmentTypeOverview
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :date, type: Date

  field :appointment_type_id, type: BSON::ObjectId
  field :appointment_type_count, type: Integer, default: 0
  field :appointment_type_label, type: String

  field :facility_id, type: BSON::ObjectId
  field :specialty_id, type: String
  field :organisation_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId

  field :data_type, type: String # can be day, week, month, year
  field :start_date, type: Date # start date
  field :end_date, type: Date
  field :data_type_range, type: Integer
  field :in_year, type: Integer
end
