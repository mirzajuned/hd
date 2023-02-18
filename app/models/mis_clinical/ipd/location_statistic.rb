class MisClinical::Ipd::LocationStatistic
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :admission_date, type: Date
  field :type, type: String
  field :location_name, type: String
  field :age_stats_fields, type: Hash
  field :gender_stats_fields, type: Hash

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end


