class ApiIntegration::User::ResponseSent
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in database: 'hg_integration_development'

  # User info
  field :role_ids, type: Array
  field :role, type: String
  field :user_id, type: String
  field :name, type: String
  field :user_integration_identifier, type: String

  # Message
  field :status, type: String
  field :status_code, type: Integer
  field :response_code, type: Integer
  field :message, type: String

  # Response
  field :response, type: Hash
end
