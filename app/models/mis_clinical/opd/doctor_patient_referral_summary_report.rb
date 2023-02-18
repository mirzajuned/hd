class MisClinical::Opd::DoctorPatientReferralSummaryReport
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :from_department_id, type: Integer, default: 440655000
  field :from_department, type: String, default: "OPD"
  
  field :referral_id, type: BSON::ObjectId

  field :referral_type_id, type: Integer
  field :referral_type_name, type: String

  field :from_specialty_id, type: String
  field :from_specialty_name, type: String

  field :to_specialty_id, type: String
  field :to_specialty_name, type: String

  field :patient_display_fields, type: Hash

  field :referral_date, type: Date
  field :referral_date_time, type: DateTime

  # even if doctor updates old record and gives reference
  field :referred_on_date, type: Date #taking opd record created_at 
  field :referred_on_date_time, type: DateTime #taking opd record created_at 

  field :referral_details, type: String
  field :referral_notes, type: String

  field :diagnoses, type: Array

  field :from_doctor_id, type: BSON::ObjectId
  field :from_doctor_name, type: String 

  field :to_doctor_id, type: BSON::ObjectId
  field :to_doctor_name, type: String 

  field :from_facility_id, type: BSON::ObjectId
  field :from_facility_name, type: String

  field :to_facility_id, type: BSON::ObjectId
  field :to_facility_name, type: String

  field :facility_id, type: BSON::ObjectId # Same data as in "from_facility_id"; keeping this extra field just for querying in method referral_id_find_or_create_by or find_or_create_by.
  field :facility_name, type: String # Same data as in "from_facility_name"; keeping this extra field just for querying in method referral_id_find_or_create_by or find_or_create_by.

  field :organisation_id, type: BSON::ObjectId # Org Id

  field :appointment_id, type: BSON::ObjectId

  # ORIGINATING IDS AND FORM NAME
  field :primary_model_id, type: BSON::ObjectId
  field :primary_model_name, type: String, default: "OpdRecord"

  field :filtering_fields, type: Hash
  field :search_fields, type: Hash
  field :custom_fields, type: Hash

  field :is_migrated, type: Boolean, default: true
end

# db.mis_clinical_opd_doctor_patient_referral_summary_reports.createIndex({"referred_on_date_time": -1, "facility_id": 1 });
# db.mis_clinical_opd_doctor_patient_referral_summary_reports.createIndex({"referred_on_date": 1, "facility_id": 1, "organisation_id": 1 });