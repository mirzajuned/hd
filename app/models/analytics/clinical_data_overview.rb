class Analytics::ClinicalDataOverview
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :date, type: Date
  field :user_id, type: BSON::ObjectId
  field :user_name, type: String
  field :patient_gender, type: String
  field :patient_age_year, type: String
  field :user_role_ids, type: Array, default: []
  field :facility_id, type: BSON::ObjectId
  field :specialty_id, type: String
  field :organisation_id, type: BSON::ObjectId

  field :diagnoses_list, type: Array, default: []
  # field :diagnoses_list_codes, type: Array, default: []

  field :procedures_list, type: Array, default: []
  # field :procedures_list_codes, type: Array, default: []

  field :ophthal_investigations_list, type: Array, default: []
  # field :ophthal_investigations_list_codes, type: Array, default: []

  field :laboratory_investigations_list, type: Array, default: []
  # field :laboratory_investigations_list_codes, type: Array, default: []

  field :radiology_investigations_list, type: Array, default: []
  # field :radiology_investigations_list_codes, type: Array, default: []
  #
  field :data_type, type: String  # can be day, week, month, year
  field :start_date, type: Date   # start date
  field :end_date, type: Date     # end date
  field :data_type_range, type: Integer # can be year(2019), can be month number(8), can be week number (32), can be day number (232)
  field :in_year, type: Integer
  field :is_migrated, type: Boolean, default: true
end
