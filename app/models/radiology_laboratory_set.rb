class RadiologyLaboratorySet
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :data, type: String
  field :specialty_id, type: String
  field :is_migrated, type: Boolean, default: true
  field :is_active, type: Boolean, default: true

  field :doctor_id, type: BSON::ObjectId

  belongs_to :user
  belongs_to :facility
  belongs_to :organisation

  validates_presence_of :name
end
