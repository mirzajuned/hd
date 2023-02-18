class AdmissionConsent
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :admission_id, type: BSON::ObjectId
  field :assigned_doctor, type: String
  field :assigned_doctor_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId
  field :consent_date, type: Date
  field :consent_path, type: String

  mount_uploader :consent_path, AdmissionConsentUploader
end
