class TaxGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :rate, type: Float, default: 0.0
  field :tax_rate_details, type: Array, default: []
  field :intrastate_tax_rate_details, type: Array, default: []
  field :interstate_tax_rate_details, type: Array, default: []
  field :ut_tax_rate_details, type: Array, default: []
  field :tax_rate_ids, type: Array, default: []

  field :is_hg_defined, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: false
  field :type, type: String

  belongs_to :organisation, optional: true
  belongs_to :country, optional: true

  validates_presence_of :name, :rate
end

# index organisation_id: 1, is_deleted: 1
