class MailRecordTracker
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :record_details, type: Hash
  field :sender_details, type: Hash
  field :receiver_details, type: Hash
  field :facility_details, type: Hash
  field :organisation_id, type: BSON::ObjectId
  field :subject, type: String
  field :mail_text, type: String
  field :disclaimer, type: String
  field :email_delivered, type: Boolean, default: :false
  field :purchase_order_id, type: BSON::ObjectId # this field will be only for PO
end
