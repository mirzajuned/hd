class OphthalmologyInvestigationData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :investigation_name, type: String
  field :specialty_id, type: String
  field :speciality_name, type: String
  field :investigation_id, type: String
  field :region, type: Array
  field :has_laterality, type: Boolean
  field :laterality, type: Array
end
