class ApiIntegration::User::Data
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  store_in database: "hg_integration_development"

  field :payload, type: Hash

  field :user_external_id, type: Integer, default: 0

  field :user_integration_identifier, type: String
  field :facility_integration_identifier, type: String
  field :organisation_integration_identifier, type: String

  field :data, type: Hash

  # Received DateTime
  field :received_date, type: Date
  field :received_time, type: DateTime

  # Sent DateTime
  field :sent_date, type: Date
  field :sent_time, type: DateTime

  # Flag
  field :request_type, type: String

  # Request State
  field :method_type, type: String
  field :status, type: String
  field :status_code, type: Integer
  field :message, type: String

  field :number_of_retries, type: Integer

  field :organisation_id, type: BSON::ObjectId
end
