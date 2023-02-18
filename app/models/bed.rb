class Bed
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :code, type: String

  field :price, type: Float

  field :status, type: Integer, default: 78848005 # Not Occupied - 78848005 | Occupied - 1669000

  field :group_id, type: String # Beds with same Name, Price & Base Code(wrt UI Form)

  field :in_use, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  embedded_in :room

  default_scope -> { where(is_deleted: false) }
end
