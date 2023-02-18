class MisClinical::Opd::LocationStatistic
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :appointment_date, type: Date
  field :type, type: String
  field :location_name, type: String
  field :age_stats_fields, type: Hash
  field :gender_stats_fields, type: Hash
  field :patient_type_stats_fields, type: Hash
  field :appointment_type_stats_fields, type: Hash

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end
