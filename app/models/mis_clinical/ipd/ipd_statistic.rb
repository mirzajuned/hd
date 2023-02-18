class MisClinical::Ipd::IpdStatistic
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :admission_date, type: Date
  field :age_stats_fields, type: Hash
  field :gender_stats_fields, type: Hash

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end

