class Analytics::ClinicalOverview
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :date, type: Date
  field :user_id, type: BSON::ObjectId
  field :user_name, type: String
  field :user_role_ids, type: Array, default: []
  field :facility_id, type: BSON::ObjectId
  field :specialty_id, type: String
  field :organisation_id, type: BSON::ObjectId

  field :total_procedures_advised, type: Integer, default: 0
  field :total_procedures_converted, type: Integer, default: 0
  field :total_procedures_counselled, type: Integer, default: 0

  field :total_diagnoses_advised, type: Integer, default: 0
  # field :total_diagnoses_converted, type: Integer,default: 0
  field :total_diagnoses_counselled, type: Integer, default: 0

  field :total_ophthal_investigations_advised, type: Integer, default: 0
  field :total_ophthal_investigations_converted, type: Integer, default: 0
  field :total_ophthal_investigations_counselled, type: Integer, default: 0

  field :total_laboratory_investigations_advised, type: Integer, default: 0
  field :total_laboratory_investigations_converted, type: Integer, default: 0
  field :total_laboratory_investigations_counselled, type: Integer, default: 0

  field :total_radiology_investigations_advised, type: Integer, default: 0
  field :total_radiology_investigations_converted, type: Integer, default: 0
  field :total_radiology_investigations_counselled, type: Integer, default: 0

  field :data_type, type: String  # can be day, week, month, year
  field :start_date, type: Date   # start date
  field :end_date, type: Date     # end date
  field :data_type_range, type: Integer # can be year(2019), can be month number(8), can be week number (32), can be day number (232)
  field :in_year, type: Integer
  field :is_migrated, type: Boolean, default: true
end
