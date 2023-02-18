class Finance::CollectionTransactionData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing
  field :receipt_id, type: String #bill receipt id or advance receipt id or refund receipt id
  field :invoice_id, type: String #if present
  field :user_id, type: String #created by
  field :facility_id, type: String
  field :organisation_id, type: String
  field :user_fullname, type: String #created by

  field :receipt_type, type: String # Bill, Refund, Advance

  field :receipt_date, type: Date
  field :receipt_time, type: DateTime
  field :receipt_display_fields, type: Hash
  field :receipt_logs, type: Array

  field :patient_display_fields, type: Hash
  field :payer_display_fields, type: Hash
  field :user_display_fields, type: Hash
  field :common_display_fields, type: Hash

  field :is_advance, type: Boolean, default: false
  field :is_refund, type: Boolean, default: false
  field :is_bill, type: Boolean, default: false

  field :custom_fields, type: Hash
  field :filter_fields, type: Hash
  field :search_fields, type: Hash

  field :store_id, type: String
  field :is_deleted, type: Boolean, default: false

  validates :receipt_id, uniqueness: true, if: -> { receipt_id.present? }
end

# db.finance_collection_transaction_data.createIndex({"receipt_date": 1, "organisation_id": 1, "is_deleted": 1 }, {background: true, 'name': 'idxformigration_create_collection'});
# db.finance_collection_transaction_data.createIndex({"invoice_id": 1 }, {background: true, 'name': 'idxformigration_soft_delete'});
