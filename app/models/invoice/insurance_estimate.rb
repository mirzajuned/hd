class Invoice::InsuranceEstimate < Invoice
  field :organisation_id, type: BSON::ObjectId
  field :tpa_insurance_workflow_id, type: BSON::ObjectId
  field :tpa_insurance_form_id, type: BSON::ObjectId # TpaInsurancePreAuthorizationForm
  field :patient_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :tpa_id, type: BSON::ObjectId
  field :estimate_display_id, type: String

  # belongs_to :tpa, class_name: "::TpaInsurancePreAuthorizationForm"
end
