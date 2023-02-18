class TpaInsuranceNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :patient_id, type: BSON::ObjectId
  field :created_by, type: BSON::ObjectId
  field :appointment_id, type: BSON::ObjectId
  field :admission_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :tpa_insurance_workflow_id, type: BSON::ObjectId
  field :room_cap_per_day, type: String
  field :note_name, type: String
  field :ailment_procedure_cap, type: String
  field :room_restrictions_comments, type: String
  field :pre_auth_admission_amount_date, type: Date
  field :tpa_date_of_reply, type: Date
  field :tpa_time_of_reply, type: String
  field :mode_of_reply, type: String
  field :addition_authorize_approval_date, type: Date
  field :addition_authorize_amount_approved, type: String
  field :addition_authorize_comments, type: String
  field :pre_auth_admission_amount_approved, type: String
  field :pre_auth_admission_comments, type: String
  field :additional_auth_amount_approved, type: String
  field :query, type: String
  field :additional_auth_comments, type: String
  field :ailment_procedure_additional_comments, type: String
  field :ailment_procedure_comments, type: String
  field :denial, type: String
  field :patient_copays, type: String

  belongs_to :tpa_insurance_workflow
end

# indexes on this model

# db.tpa_insurance_notes.createIndex({ patient_id: 1, tpa_insurance_workflow_id: 1 })
