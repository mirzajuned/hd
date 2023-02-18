# used
class Inventory::Category
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend Enumerize

  field :name, type: String
  field :description, type: String
  field :last_edited_by, type: String
  field :is_disable, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  field :dispensing_unit_ids, type: Array, default: []
  field :store_ids, type: Array, default: [] # store all linked store ids
  field :prefix, type: String
  field :vendor_ids, type: Array, default: []

  # category_settings
  field :type, type: Integer # Medication, Optical, Asset
  field :multiple_variants, type: Boolean, default: false
  field :stockable, type: Boolean, default: true

  field :default_possible_variants, type: Array, default: []
  field :default_item_type, type: String, default: 'Number'
  field :created_from, type: String

  field :expiry_days, type: Integer

  enumerize :type, in: { medication: 0, optical: 1, asset: 2, miscellaneous: 3, iol: 4 }, predicates: true

end
