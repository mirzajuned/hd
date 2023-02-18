# 1  Metrics/LineLength
# --
# 1  Total
class AdviceSet
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :name, type: String
  field :content, type: String
  field :counter, type: Integer, default: 0
  field :created_date, type: Date
  field :created_by, type: String
  field :signature, type: String
  field :primary_language, type: String
  field :specialty_id, type: String
  field :level, type: String # user, organisation, facility
  field :is_migrated, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false

  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  embeds_many :language_advice_subset, class_name: '::LanguageAdviceSubset'

  accepts_nested_attributes_for :language_advice_subset, reject_if: proc { |attributes| attributes['content'].blank? || attributes['content'] == '<br>' }, allow_destroy: true, class_name: '::LanguageAdviceSubset'
end
