class PatientCertificate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :certificatetype, type: String

  belongs_to :patient
end
