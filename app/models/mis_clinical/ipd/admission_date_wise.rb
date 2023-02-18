class MisClinical::Ipd::AdmissionDateWise
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :created_date, type: Date
  # field :admitting_doctor, type: String
  # field :admitting_doctor_id, type: BSON::ObjectId
  field :admission_stats_fields, type: Hash

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end
