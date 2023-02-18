class OfferManager::DynamicCode
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :dynamic_code, type: String

  field :reference_by_id, type: BSON::ObjectId
  field :reference_by, type: String

  field :applied_by_id, type: BSON::ObjectId
  field :applied_by, type: String

  field :applied_at_facility_id, type: BSON::ObjectId
  field :applied_at_facility_name, type: String
  field :applied_date, type: Date
  field :applied_datetime, type: Time

  field :is_used, type: Boolean, default: false

  embedded_in :offer_manager, class_name: '::OfferManager'
end
