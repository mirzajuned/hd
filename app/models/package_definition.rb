class PackageDefinition
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :display_name, type: String

  field :service_group_id, type: String
  field :service_sub_group_id, type: String

  field :valid_from, type: Date
  field :valid_till, type: Date

  field :room_type, type: String

  field :service_type, type: String
  field :service_type_code_name, type: String
  field :service_type_code, type: String

  field :package_group_id, type: String

  field :department_id, type: String
  field :specialty_id, type: String
  field :sub_specialty_id, type: String

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :user_id, type: BSON::ObjectId

  # Indexes
  # index({ package_group_id: 1 }) # db.package_definitions.createIndex({ package_group_id: 1 })
end
