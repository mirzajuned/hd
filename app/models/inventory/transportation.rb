class Inventory::Transportation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :is_disable, type: Boolean, default: false
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  validates :name, presence: { message: 'Transportation Name cannot be blank.' }
end

