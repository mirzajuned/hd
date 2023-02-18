class Finance::BillTypeSummary
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :facility_timezone, type: String

  field :department_id, type: Integer
  field :department_name, type: String
  field :department_order, type: Integer

  field :invoice_id, type: BSON::ObjectId
  field :receipt_date, type: Date
  field :receipt_datetime, type: DateTime
  field :bill_type, type: String # free/paid/discounted
  field :receipt_display_fields, type: Hash

  field :user_id, type: BSON::ObjectId
  field :user_display_fields, type: Hash

  field :patient_id, type: BSON::ObjectId
  field :patient_display_fields, type: Hash

  field :is_migrated, type: Boolean, default: true
  
  validates :invoice_id, uniqueness: true, if: -> { invoice_id.present? }
end

# db.finance_bill_type_summaries.createIndex({"receipt_datetime": -1, "organisation_id": 1, "facility_id": 1, "bill_type": 1 }, {name:"date_bill_type_indexes"});