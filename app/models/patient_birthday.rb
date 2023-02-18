class PatientBirthday
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :patient_id, type: String
  field :dob, type: String
end
