class PatientRadiologyInvestigation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  # field :name, type: String
  # field :loinc_code, type: String
  # field :laterality, type: String
  # field :is_spine, type: String
  # field :advised_date, type: DateTime
  # field :full_code, type: String
  # field :radiology_options_collection, type: Array
  # field :template_id, type: Integer
  # field :specialty_id, type: Integer

  belongs_to :patient
  belongs_to :user
  belongs_to :facility
end
