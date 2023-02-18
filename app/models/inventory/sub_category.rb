# used
class Inventory::SubCategory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :is_disable, type: Boolean, default: false
  field :category_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  belongs_to :category, optional: true

  validates :name, presence: true

  # category_settings
end
