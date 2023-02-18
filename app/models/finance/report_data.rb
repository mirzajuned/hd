class Finance::ReportData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :invoice_id, type: String #Invoice id or advance receipt id
  field :organisation_id, type: String
  field :facility_id, type: String
  field :receipt_created_at, type: DateTime
  field :receipt_updated_at, type: DateTime
  field :receipt_display_fields, type: Hash
  # field :cancelled_invoice_fields, type: Hash
  field :refund_invoice_fields, type: Hash
  field :patient_display_fields, type: Hash
  field :payer_display_fields, type: Hash
  field :user_display_fields, type: Hash
  field :common_display_fields, type: Hash

  field :appointment_display_fields, type: Hash
  field :admission_display_fields, type: Hash

  field :is_advance, type: Boolean, default: false
  field :is_cancelled, type: Boolean, default: false
  field :is_refunded, type: Boolean, default: false
  field :has_refund, type: Boolean, default: false

  field :has_logs, type: Boolean, default: false
  field :has_advance_history, type: Boolean, default: false
  field :has_refund_history, type: Boolean, default: false
  field :refunds_count, type: Integer, default: 0

  field :receipt_logs, type: Array
  field :advance_history, type: Array
  field :refund_history, type: Array

  field :is_migrated, type: Boolean, default: true
  field :custom_fields, type: Hash
  field :filter_fields, type: Hash
  field :search_fields, type: Hash
  
  field :is_deleted, type: Boolean, default: false
  
  embeds_many :services, class_name: '::Invoice::Service'
  embeds_many :advance_payment_breakups, class_name: '::Invoice::AdvancePaymentBreakup'
  embeds_many :payment_received_breakups, class_name: '::Invoice::PaymentReceivedBreakup'
  embeds_many :payment_pending_breakups, class_name: '::Invoice::PaymentPendingBreakup'
  embeds_many :sequences, class_name: '::Invoice::Sequence'

  accepts_nested_attributes_for :services
  accepts_nested_attributes_for :advance_payment_breakups
  accepts_nested_attributes_for :payment_received_breakups
  accepts_nested_attributes_for :payment_pending_breakups
  accepts_nested_attributes_for :sequences

  validates :invoice_id, uniqueness: true, if: -> { invoice_id.present? }
end

# db.finance_report_data.createIndex({"receipt_display_fields.bill_date": -1, "facility_id": 1 });
# db.finance_report_data.createIndex({"receipt_display_fields.bill_date": 1, "organisation_id": 1 });
# db.finance_report_data.createIndex({"receipt_created_at": 1, "organisation_id": 1 });
# db.finance_report_data.createIndex({"receipt_updated_at": 1, "organisation_id": 1 });
# db.finance_report_data.createIndex({"payment_received_breakups.time": 1, "organisation_id": 1 });
# db.finance_report_data.createIndex({"receipt_display_fields.payment_time": 1, "organisation_id": 1 });
# db.finance_report_data.createIndex({"receipt_display_fields.payment_time": 1, "organisation_id": 1 });
# db.finance_report_data.createIndex({"refund_invoice_fields.return_time": 1, "organisation_id": 1 });
