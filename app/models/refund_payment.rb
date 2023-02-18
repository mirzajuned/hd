class RefundPayment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :reason, type: String

  field :amount, type: Float

  field :invoice_received_amount, type: Float
  field :invoice_settled_amount, type: Float
  field :invoice_total_amount, type: Float

  field :advance_remaining_amount, type: Float
  field :advance_total_amount, type: Float

  field :currency_symbol, type: String
  field :currency_id, type: String
  field :amount_remaining, type: Float
  field :mode_of_payment, type: String
  # field :payment_date, type: DateTime, default: Date.today
  field :payment_old_date, type: DateTime
  field :payment_date, type: Date
  field :payment_time, type: Time#, default: Time.now

  field :cash, type: Float
  field :card, type: Float
  field :card_number, type: Integer
  field :cheque_date, type: String
  field :cheque_note, type: String
  field :transfer_date, type: String
  field :transfer_note, type: String
  field :other_note, type: String
  field :card_transaction_note, type: String
  field :paytm_transaction_id, type: String
  field :paytm_transaction_note, type: String
  field :gpay_transaction_id, type: String
  field :gpay_transaction_note, type: String
  field :phonepe_transaction_id, type: String
  field :phonepe_transaction_note, type: String
  field :transfer_date, type: String # for Online transfer
  field :transfer_note, type: String
  field :other_transaction_id, type: String
  field :other_note, type: String
  field :refund_display_id, type: String
  field :bill_number, type: String
  field :order_number, type: String
  field :advance_display_id, type: String

  field :refund_history, type: Array, default: []

  field :type, type: String

  field :department_id, type: String
  field :department_name, type: String

  field :level, type: String # eg. patient, invoice
  field :refund_state, type: String, default: 'None'

  field :is_migrated, type: Boolean, default: false

  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :invoice_id, type: BSON::ObjectId
  field :order_id, type: BSON::ObjectId
  field :advance_payment_id, type: BSON::ObjectId

  field :is_deleted, type: Boolean, default: false

  field :specialty_id, type: String

  field :return_charges, type: Float, default: 0.0
  field :refund_type, type: String
  field :refund_payment_type, type: String

  field :store_id, type: BSON::ObjectId

  # saving data here for multiple refund
  field :is_canceled, type: Boolean, default: false
  field :canceled_by, type: String
  field :canceled_by_id, type: String
  field :cancel_date, type: Date

  field :refunded_by, type: String
  field :refunded_by_id, type: String
  field :is_refunded, type: Boolean, default: false
  field :refund_date, type: Date
  field :refund_time, type: Time

  field :bkp_refund_display_id, type: String
  embeds_many :sequences, class_name: '::RefundPayment::Sequence'
  accepts_nested_attributes_for :sequences

  belongs_to :patient

  before_save :reset_mop_fields

  def reset_mop_fields
    mop = mode_of_payment
    self.cash = (cash if mop == 'Cash') || nil
    self.card = (card if mop == 'Card') || nil
    self.card_number = (card_number if mop == 'Card') || nil
    self.cheque_date = (cheque_date if mop == 'Cheque') || nil
    self.cheque_note = (cheque_note if mop == 'Cheque') || nil
    self.transfer_date = (transfer_date if mop == 'Online Transfer') || nil
    self.transfer_note = (transfer_note if mop == 'Online Transfer') || nil
    self.other_note = (other_note if mop == 'Others') || nil
  end
end

# db.refund_payments.createIndex({"created_at": 1, "organisation_id": 1 });
# db.refund_payments.createIndex({"updated_at": 1, "organisation_id": 1 });