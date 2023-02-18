class ApiIntegration::User::ResponseReceived
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  store_in database: 'hg_integration_development'

  # User info
  field :role_ids, type: Array
  field :role, type: String
  field :user_external_id, type: String
  field :name, type: String
  field :user_integration_identifier, type: String
  field :data, type: Hash

  # Message
  field :status, type: String
  field :status_code, type: Integer
  field :response_code, type: Integer
  field :message, type: String

  # Response
  field :response, type: Hash
end
