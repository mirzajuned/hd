class MisClinical::Opd::PatientReferralStats
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :created_date, type: Date
  field :referral_name, type: String
  field :referral_type_id, type: String
  field :age_stats_fields, type: Hash
  field :gender_stats_fields, type: Hash
  field :patient_type_stats_fields, type: Hash
  field :appointment_type_stats_fields, type: Hash

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end
