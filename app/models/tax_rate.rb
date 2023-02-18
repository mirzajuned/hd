class TaxRate
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :rate, type: Float
  field :type, type: String

  field :is_hg_defined, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false

  field :user_id, type: BSON::ObjectId

  belongs_to :country, optional: true
  belongs_to :organisation, optional: true

  validates_presence_of :name, :rate, :type
end

# index organisation_id: 1, is_deleted: 1
