class OtRoom
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :specialty_id, type: String
  field :capacity, type: Integer
  field :is_deleted, type: Boolean, default: false
end
