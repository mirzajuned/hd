class MisClinical::Opd::OpdStatistic
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :appointment_date, type: Date
  field :appointment_stats_fields, type: Hash
  field :patient_stats_fields, type: Hash
  field :turnaround_time_stats_fields, type: Hash
  field :appointment_type_stats_fields, type: Hash

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end

