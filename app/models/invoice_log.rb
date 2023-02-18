class InvoiceLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :bill_number, type: String
  field :details, type: String
  field :invoice_type, type: String
  field :invoice_date, type: Date
  field :old_total, type: Float
  field :new_total, type: Float
  field :comment, type: String
  field :invoice_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :username, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :bkp_bill_number, type: String
end
