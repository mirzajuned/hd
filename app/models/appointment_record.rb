class AppointmentRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  field :appointment_id, type: BSON::ObjectId
  field :opd_record_ids, type: Array, default: []
  field :counsellor_record_ids, type: Array, default: []

  embeds_many :diagnoses, class_name: "::Diagnosis"
  embeds_many :procedures, class_name: "::Procedure"
  embeds_many :ophthal_investigations, class_name: "::OphthalmologyInvestigation"
  embeds_many :laboratory_investigations, class_name: "::LaboratoryInvestigation"
  embeds_many :radiology_investigations, class_name: "::RadiologyInvestigation"

  accepts_nested_attributes_for :diagnoses, class_name: "::Diagnosis"
  accepts_nested_attributes_for :procedures, class_name: "::Procedure"
  accepts_nested_attributes_for :ophthal_investigations, class_name: "::OphthalmologyInvestigation"
  accepts_nested_attributes_for :laboratory_investigations, class_name: "::LaboratoryInvestigation"
  accepts_nested_attributes_for :radiology_investigations, class_name: "::RadiologyInvestigation"
end
