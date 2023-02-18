class PatientInsurance
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :patient_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :tpa_form_id, type: BSON::ObjectId
  field :insurance_id, type: BSON::ObjectId
  field :insurance_contact_id, type: BSON::ObjectId
  field :insurance_name, type: String     # name of the insurance company
  field :insurance_address, type: String
  field :insurance_status, type: String   # Waiting,Approved,Rejected
  field :insurance_contact_no, type: String
  field :insurance_contact_person, type: String
  field :insurance_policy_no, type: String # policy no of patient insurance
  field :insurance_policy_expiry_date, type: Date

  belongs_to :patient
end

# db.patient_insurances.createIndex({ patient_id: 1 })
