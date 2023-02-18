class MisClinical::Opd::DoctorPatientReferralStats
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :referred_date, type: Date

  field :intra_facility_count, type: Integer, default: 0
  field :inter_facility_count, type: Integer, default: 0
  field :outside_organisation_count, type: Integer, default: 0

  field :doctor_id, type: BSON::ObjectId
  field :doctor_name, type: String 

  field :facility_id, type: BSON::ObjectId 
  field :facility_name, type: String

  field :organisation_id, type: BSON::ObjectId # Org Id

  field :is_migrated, type: Boolean, default: true
end

# db.mis_clinical_opd_doctor_patient_referral_stats.createIndex({"referred_date": -1, "facility_id": 1 });
