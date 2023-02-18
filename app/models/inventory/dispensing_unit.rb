# used
class Inventory::DispensingUnit
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :last_edited_by, type: String
  field :is_disable, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  field :category_ids, type: Array, default: []
  field :created_from, type: String

end
