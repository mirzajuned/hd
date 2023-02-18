class ApiIntegration::Order::ResponseReceived
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  store_in database: "hg_integration_development"

  # MrNo. AppointmentID
  field :mr_no, type: String
  field :appointment_integration_identifier, type: String
  field :visit_integration_identifier, type: String
  field :visit_type, type: String
  field :data, type: Hash

  # Message
  field :status, type: String
  field :status_code, type: Integer
  field :response_code, type: String
  field :message, type: String

  # Response
  field :response, type: Hash
end
