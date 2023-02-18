class PatientIdentifier
  include Mongoid::Document
  include Mongoid::Timestamps

  field :bkp_patient_org_id, type: String
  field :patient_org_id, type: String

  embeds_many :sequences, class_name: '::PatientIdentifier::Sequence'

  belongs_to :patient
  belongs_to :organisation
end
