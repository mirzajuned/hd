class SurgeryPackage::Item
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :type, type: String

  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  validates_presence_of :name, :type, :user_id, :facility_id, :organisation_id
end
