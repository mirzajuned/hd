class MedicalFamilyHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :medical_history, type: String
  field :family_history, type: String
end
