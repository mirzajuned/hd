class PatientRegistrationSource
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :source_type, type: String
  field :source_info, type: String

  belongs_to :patient
  # belongs_to :user
  # belongs_to :facility
end
