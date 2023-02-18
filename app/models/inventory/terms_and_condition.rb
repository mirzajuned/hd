class Inventory::TermsAndCondition
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :type, type: String
  field :description, type: String
  field :is_disable, type: Boolean, default: false
  field :created_by, type: String
  field :created_on, type: Time

  field :organisation_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId

  validates :type, presence: true
  validates :description, presence: true
end