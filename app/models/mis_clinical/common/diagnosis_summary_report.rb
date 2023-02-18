class MisClinical::Common::DiagnosisSummaryReport
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :specialty_id, type: String
  field :specialty_name, type: String

  field :patient_display_fields, type: Hash

  field :from_department, type: String, default: "OPD"
  field :from_department_id, type: Integer, default: 440655000

  # Check if diagnosis is (ICD or Custom) OR (Provisional or Comment Box); True- ICD/Custom & False- Provisional/CommentBox
  field :is_diagnosis_coded, type: Boolean, default: true

  field :diagnosis_id, type: BSON::ObjectId
  field :diagnosis_type, type: String, default: "Icd Diagnosis"
  field :diagnosis_type_label, type: String, default: "ICD"
  field :diagnosis_type_id, type: Integer, default: 447634004

  field :diagnosis_date, type: Date
  field :diagnosis_date_time, type: DateTime

  field :partial_diagnosis_name, type: String # empty in case of Provisional/CommentBox
  field :laterality_name, type: String # empty in case of Provisional/CommentBox
  field :laterality_abbr, type: String # empty in case of Provisional/CommentBox
  field :full_diagnosis_name, type: String
  field :diagnosis_original_name, type: String
  field :diagnosis_comment, type: String
  field :users_comment, type: String

  field :partial_diagnosis_code, type: String
  field :has_laterality, type: Boolean, default: false
  field :laterality_code, type: String  
  field :laterality_position, type: String
  field :full_diagnosis_code, type: String
  field :full_diagnosis_code_length, type: Integer
  field :full_diagnosis_code_piped, type: String # Ex- h25|0|1|1 (pipe "|" separator) 

  field :doctor_id, type: BSON::ObjectId # Doctor Id
  field :doctor_name, type: String # Doctor Name 

  field :facility_id, type: BSON::ObjectId # Facility Id
  field :facility_name, type: String # Facility Name

  field :organisation_id, type: BSON::ObjectId # Org Id

  # ORIGINATING IDS AND FORM NAME
  field :case_sheet_id, type: BSON::ObjectId
  field :primary_model_id, type: BSON::ObjectId
  field :primary_model_name, type: String
  field :created_from_form_id, type: Integer
  field :created_from_form_name, type: String

  field :secondary_model_present, type: Boolean, default: false
  field :secondary_model_info, type: Array

  field :filtering_fields, type: Hash
  field :search_fields, type: Hash
  field :custom_fields, type: Hash

  field :is_migrated, type: Boolean, default: true
end


# db.mis_clinical_common_diagnosis_summary_reports.createIndex({"diagnosis_date_time": -1, "facility_id": 1})