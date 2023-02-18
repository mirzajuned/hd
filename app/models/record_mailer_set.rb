class RecordMailerSet
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :content, type: String
  field :name, type: String
  field :user_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :email_delivered, type: Boolean, default: false
end
