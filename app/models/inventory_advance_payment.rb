class InventoryAdvancePayment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :patient_org_id, type: String
  field :prescription_id, type: String
  field :reason, type: String
  field :advance_amount, type: Float
  field :department_id, type: Float
  field :patient_id, type: String
  field :patient_name, type: String
  field :facility_id, type: String
  field :appointment_id, type: String
  field :doctor_name, type: String
end
