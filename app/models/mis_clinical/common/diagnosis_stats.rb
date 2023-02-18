class MisClinical::Common::DiagnosisStats
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :organisation_id, type: BSON::ObjectId 

  field :facility_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :facility_timezone, type: String

  field :department_id, type: Integer
  field :department_name, type: String
  field :department_order, type: Integer

  field :specialty_id, type: String
  field :specialty_name, type: String

  field :doctor_id, type: BSON::ObjectId
  field :doctor_name, type: String

  field :diagnosis_date, type: Date
  field :diagnosis_code, type: String
  field :diagnosis_id, type: BSON::ObjectId
  field :diagnosis_name, type: String
  
  field :patient_age_fields, type: Hash
  field :patient_gender_fields, type: Hash
  field :gender_wise_age, type: Hash

  field :is_migrated, type: Boolean, default: true

  field :filter_fields, type: Hash
  field :search_fields, type: Hash
end

# db.mis_clinical_common_diagnosis_stats.createIndex({"diagnosis_date": -1, "facility_id": 1})
# db.mis_clinical_common_diagnosis_stats.createIndex({"diagnosis_original_name": 1, "facility_id": 1})