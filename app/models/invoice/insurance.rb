class Invoice::Insurance < Invoice
  field :net_amount, type: Float
  field :mode_of_payment_insurance, type: String
  field :insurance_payed, type: Boolean
  field :amount_paid_tpa, type: Float
  field :amount_paid_patient, type: Float
  field :insurance_display_id, type: String
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId

  belongs_to :tpa, class_name: "::Inpatient::Insurance::Tpa"
end
