class ServiceSubGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :is_active, type: Boolean, default: true
  field :in_use, type: Boolean, default: false

  field :user_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  validates_presence_of :name, :user_id, :organisation_id
  validates_uniqueness_of :name, case_sensitive: false, scope: :organisation_id

  # Indexes
  # index({ organisation_id: 1 }) # db.service_sub_groups.createIndex({ organisation_id: 1 })
end
