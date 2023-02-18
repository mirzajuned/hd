class ApiIntegration::ClientIntegrationToken
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  field :token, type: String
  field :credential_payload, type: Hash
  field :client, type: String
  field :client_id, type: String
  field :url, type: String

  field :facility_integration_identifier, type: String
  field :facility_id, type: BSON::ObjectId

  field :organisation_integration_identifier, type: String
  field :organisation_id, type: BSON::ObjectId
end
