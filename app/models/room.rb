class Room
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :type, type: String
  field :code, type: String

  field :total_beds, type: Integer, default: 0

  field :in_use, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  embeds_many :beds # , dependent: :destroy
  accepts_nested_attributes_for :beds, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true

  belongs_to :ward

  default_scope -> { where(is_deleted: false) }
end
