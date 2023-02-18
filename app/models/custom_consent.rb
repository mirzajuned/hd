class CustomConsent
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :name, type: String
  field :content, type: String
  field :primary_language, type: String
  field :specialty_id, type: String
  field :level, type: String
  field :is_deleted, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: true
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  embeds_many :language_consent_subsets

  accepts_nested_attributes_for :language_consent_subsets, reject_if: proc { |attributes| attributes['content'].blank? || attributes['content'] == '<br>' }, allow_destroy: true
end
