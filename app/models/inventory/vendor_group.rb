# used
class Inventory::VendorGroup
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :last_edited_by, type: String
  field :vendor_ids, type: Array
  field :is_disable, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId

end
