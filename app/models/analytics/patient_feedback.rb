class Analytics::PatientFeedback
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :date, type: Date

  field :usability, type: Float, default: 0.0
  field :waiting, type: Float, default: 0.0
  field :cleanliness, type: Float, default: 0.0
  field :overallcare, type: Float, default: 0.0
  field :recommendation, type: Float, default: 0.0
  field :average_rating, type: Float, default: 0.0
  field :total_count, type: Integer, default: 0

  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :data_type, type: String  # can be day, week, month, year
  field :start_date, type: Date   # start date
  field :end_date, type: Date     # end date
  field :data_type_range, type: Integer # can be year(2019), can be month number(8), can be week number (32), can be day number (232)
  field :in_year, type: Integer
end
