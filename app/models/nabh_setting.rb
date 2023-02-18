class NabhSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  field :enabled, type: Boolean, default: false
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  belongs_to :facility
  belongs_to :organisation
end
