class ApiIntegration::DataRequest
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  store_in database: 'hg_integration_development'

  # Request Params
  field :payload, type: Hash, default: {}

  # Received/Sent DateTime
  field :request_date, type: Date
  field :request_time, type: DateTime

  field :additional_data, type: Hash
  # Flag
  field :request_type, type: String

  # Request From
  field :url, type: String

  field :number_of_retries, type: Integer

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
end
