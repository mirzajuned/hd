class Inventory::SubStore
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :is_active, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId

  belongs_to :store, class_name: '::Inventory::Store'
end
