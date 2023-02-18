class CustomRadiologyInvestigation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :is_deleted, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :investigation_name, type: String
  field :specialty_id, type: String
  field :investigation_id, type: String
  field :investigation_type, type: String
  field :is_migrated, type: Boolean, default: true
  field :level, type: String, default: 'organisation'

end
