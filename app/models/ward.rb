class Ward
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :code, type: String

  field :total_rooms, type: Integer, default: 0

  field :in_use, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId

  has_many :rooms, dependent: :destroy

  accepts_nested_attributes_for :rooms, allow_destroy: true

  default_scope -> { where(is_deleted: false) }

  # INTERNAL - Restore Ward, Room, Bed
  def restore
    update_attributes(is_deleted: false)

    rooms.unscoped.each do |room|
      room.beds.unscoped.update_all(is_deleted: false) if room.update_attributes(is_deleted: false)
    end
  end

  # Indexes
  # index({ facility_id: 1 }) # db.wards.createIndex({ facility_id: 1 })
end
