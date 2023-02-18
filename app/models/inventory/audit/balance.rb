class Inventory::Audit::Balance
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :facility_id, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :sub_store_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  # field :user_id, type: BSON::ObjectId
  # field :item_id, type: BSON::ObjectId
  # field :variant_id, type: BSON::ObjectId
  # field :lot_id, type: BSON::ObjectId

  field :opening_stock, type: Integer
  field :closing_stock, type: Integer
  field :opening_amount, type: Float
  field :closing_amount, type: Float
  field :date, type: Date

  validates :store_id, presence: true
  validates :sub_store_id, presence: true
end
