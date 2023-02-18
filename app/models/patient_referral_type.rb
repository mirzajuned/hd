class PatientReferralType
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :is_deleted, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: true

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  # Relation
  belongs_to :referral_type
  belongs_to :sub_referral_type
  belongs_to :patient
  belongs_to :appointment

  # Validation
  validates_presence_of :referral_type_id, :sub_referral_type_id, :patient_id, :appointment_id

  # Indexes
  # db.patient_referral_types.createIndex({ appointment_id: 1 })
  # db.patient_referral_types.createIndex({ patient_id: 1 })
end
