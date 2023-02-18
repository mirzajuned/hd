class PatientHistoryData
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :name, type: String
  field :side, type: String
  field :duration, type: String
  field :duration_unit, type: String
  field :comment, type: String
  field :history_comment, type: String
  field :record_created_date, type: DateTime
  field :history_type, type: String
  field :cured_on, type: DateTime

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :personal_history_record_id, type: BSON::ObjectId
  field :record_id, type: String
end
