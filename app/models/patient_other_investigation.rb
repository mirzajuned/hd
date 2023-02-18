class PatientOtherInvestigation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  # field :name, type: String
  # field :loinc_class, type: String
  # field :loinc_code, type: String
  # field :advised_date, type: Date
  # field :laboratorytest_id, type: String
  # field :investigation_fullcode, type: String

  belongs_to :patient
  belongs_to :user
  belongs_to :facility
end
