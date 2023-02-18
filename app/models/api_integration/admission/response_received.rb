class ApiIntegration::Admission::ResponseReceived
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  store_in database: 'hg_integration_development'

  # MrNo. AppointmentID
  field :mr_no, type: String
  field :admission_integration_identifier, type: String

  # Message
  field :response, type: Hash
  field :response_code, type: String
  field :data, type: Hash

  field :status, type: String
  field :status_code, type: Integer
  field :message, type: String
end
