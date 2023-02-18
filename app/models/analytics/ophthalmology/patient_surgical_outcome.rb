class Analytics::Ophthalmology::PatientSurgicalOutcome
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # fields
  field :speciality_id, type: String

  field :organisation_id, type: BSON::ObjectId # Required
  field :facility_id, type: BSON::ObjectId # Required
  field :speciality_id, type: String # Required

  field :patient_name, type: String # Required
  field :patient_id, type: BSON::ObjectId # Required
  field :admission_id, type: BSON::ObjectId
  field :patient_gender, type: String
  field :patient_age, type: Integer
  field :patient_dob_year, type: Integer
  field :icd_code, type: String # Required

  field :type_of_surgery_performed, type: String # Required
  field :surgery_code, type: String # Required
  field :laterality, type: String # Required
  field :surgery_date, type: Date # Required
  field :has_complication, type: String
  field :complication_text, type: String
  field :doctor, type: BSON::ObjectId # Required
  field :advised_by_doc, type: BSON::ObjectId

  field :uncorrected_va_pre_surgery_percentage_left_near, type: Float, default: 0.0 # Required
  field :uncorrected_va_pre_surgery_percentage_left_far, type: Float, default: 0.0 # Required
  field :bestcorrected_va_post_surgery_percentage_left_near, type: Float, default: 0.0 # Required
  field :bestcorrected_va_post_surgery_percentage_left_far, type: Float, default: 0.0 # Required

  field :uncorrected_va_pre_surgery_percentage_right_near, type: Float, default: 0.0 # Required
  field :uncorrected_va_pre_surgery_percentage_right_far, type: Float, default: 0.0 # Required
  field :bestcorrected_va_post_surgery_percentage_right_near, type: Float, default: 0.0 # Required
  field :bestcorrected_va_post_surgery_percentage_right_far, type: Float, default: 0.0 # Required

  field :uncorrected_va_pre_surgery_left_near, type: String
  field :uncorrected_va_pre_surgery_left_far, type: String
  field :uncorrected_va_recorded_date_pre_surgery_left, type: Date

  field :bestcorrected_va_pre_surgery_left_near, type: String
  field :bestcorrected_va_pre_surgery_left_far, type: String
  field :bestcorrected_va_recorded_date_pre_surgery_left, type: Date
  field :uncorrected_va_pre_surgery_logmar_left, type: String
  field :bestcorrected_va_pre_surgery_logmar_left, type: String
  field :uncorrected_va_post_surgery_logmar_left, type: String

  field :uncorrected_va_pre_surgery_right_near, type: String
  field :uncorrected_va_pre_surgery_right_far, type: String
  field :uncorrected_va_recorded_date_pre_surgery_right, type: Date

  field :bestcorrected_va_pre_surgery_right_near, type: String
  field :bestcorrected_va_pre_surgery_right_far, type: String
  field :bestcorrected_va_recorded_date_pre_surgery_right, type: Date

  field :uncorrected_va_pre_surgery_logmar_right, type: String
  field :bestcorrected_va_pre_surgery_logmar_right, type: String
  field :uncorrected_va_post_surgery_logmar_right, type: String

  field :uncorrected_va_post_surgery_left_near, type: String
  field :uncorrected_va_post_surgery_left_far, type: String
  field :uncorrected_va_recorded_date_post_surgery_left, type: Date

  field :bestcorrected_va_post_surgery_left_near, type: String
  field :bestcorrected_va_post_surgery_left_far, type: String
  field :bestcorrected_va_recorded_date_post_surgery_left, type: Date

  field :bestcorrected_va_post_surgery_logmar_left, type: String
  field :uncorrected_va_pre_surgery_percentage_left, type: String
  field :bestcorrected_va_post_surgery_percentage_left, type: String

  field :uncorrected_va_post_surgery_right_near, type: String
  field :uncorrected_va_post_surgery_right_far, type: String
  field :uncorrected_va_recorded_date_post_surgery_right, type: Date

  field :bestcorrected_va_post_surgery_right_near, type: String
  field :bestcorrected_va_post_surgery_right_far, type: String
  field :bestcorrected_va_recorded_date_post_surgery_right, type: Date

  field :bestcorrected_va_post_surgery_logmar_right, type: String
  field :uncorrected_va_pre_surgery_percentage_right, type: String
  field :bestcorrected_va_post_surgery_percentage_right, type: String

  field :complete_data, type: Boolean
end

# index needed on organisation id facility id
