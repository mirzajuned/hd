class PatientNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :comment, type: String
  field :creation_date, type: Date
  field :completion_date, type: Date
  field :user_id, type: String
  field :created_by, type: String
  field :organisation_id, type: String
  field :is_complete, type: Boolean, default: false
  field :patient_id, type: String
end
