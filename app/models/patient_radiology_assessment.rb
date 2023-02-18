class PatientRadiologyAssessment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :radiology_investigations, type: Array, default: []

  field :payment, type: String, default: 'Unpaid'
  field :status, type: String, default: 'Not Started'
  field :appointment_id, type: String

  field :invoice_id, type: String
  field :report_id, type: Array, default: []
  field :unavailable_test_id, type: Array
end
