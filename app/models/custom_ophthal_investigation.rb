class CustomOphthalInvestigation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :is_deleted, type: Boolean, default: false
  field :is_uploaded, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :investigation_name, type: String
  field :specialty_id, type: Integer
  field :investigation_id, type: String
  field :region, type: Array
  field :has_laterality, type: Boolean
  field :laterality, type: Array
  field :level, type: String, default: 'organisation'

end
