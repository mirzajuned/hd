class CounsellorRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :patient_discussions, type: Hash, default: {}
  field :patient_surgery_package, type: Hash, default: {}

  field :history_comment, type: String
  field :diagnosis_comment, type: String
  field :investigation_comment, type: String
  field :procedure_comment, type: String

  field :appointment_record_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId
  field :appointment_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :free_form_procedures, type: Hash, default: {}
  field :free_form_diagnoses, type: Hash, default: {}
  field :free_form_investigations, type: Hash, default: {}

  field :case_sheet_id, type: BSON::ObjectId

  # insurance fields
  field :patient_insurance_id, type: BSON::ObjectId
  # field :tpa_contact_id, type: BSON::ObjectId
  field :insurance_contact_id, type: BSON::ObjectId
  field :insurance_name, type: String     # name of the insurance company
  field :insurance_address, type: String
  field :insurance_status, type: String   # Waiting,Approved,Rejected
  field :insurance_contact_no, type: String
  field :insurance_contact_person, type: String
  field :insurance_policy_no, type: String # policy no of patient insurance
  field :insurance_policy_expiry_date, type: Date
  field :insurance_sum_insured, type: String

  field :specialty_id, type: String

  field :is_insured, type: String, default: "No"

  field :is_legacy, type: Boolean, default: false

  embeds_many :procedures
  embeds_many :diagnoses
  embeds_many :ophthal_investigations, class_name: '::OphthalmologyInvestigation'
  embeds_many :radiology_investigations
  embeds_many :laboratory_investigations

  accepts_nested_attributes_for :procedures
  accepts_nested_attributes_for :diagnoses
  accepts_nested_attributes_for :ophthal_investigations, class_name: '::OphthalmologyInvestigation'
  accepts_nested_attributes_for :radiology_investigations
  accepts_nested_attributes_for :laboratory_investigations

  validates_presence_of :organisation_id, :facility_id, :user_id, :patient_id, :appointment_id
end
