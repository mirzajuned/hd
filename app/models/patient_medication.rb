class PatientMedication
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  belongs_to :patient
  belongs_to :user
  belongs_to :facility
end
