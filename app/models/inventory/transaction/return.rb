class Inventory::Transaction::Return
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :return_bill_number, type: String

  field :transaction_date, type: Date

  field :status, type: String, default: 'Pending'
  field :note, type: String #same as refund_reason

  field :entered_by, type: String
  field :entry_type, type: String

  field :return_date, type: Date
  field :return_time, type: Time
  field :total_cost, type: Float
  field :return_charges, type: Float
  field :return_amount, type: Float
  field :mode_of_payment, type: String
  field :other_transaction_id, type: String
  field :other_note, type: String
  field :comments, type: String
  field :return_type # return against invoice & return against patient
  field :return_from_cancellation, type: Boolean, default: false # To check whether return is made after cancel of invoice

  field :tax_breakup, type: Array, default: []
  field :taxable_amount, type: Float, default: 0.0
  # Invoice Info
  field :invoice_id, type: BSON::ObjectId
  field :invoice_received_amount, type: Float # Invoice payment received
  field :invoice_total_amount, type: Float # To save invoice total amount including discount

  field :specialty_id, type: String
  field :currency_symbol, type: String
  field :currency_id, type: String
  field :specialty_id, type: String

  field :department_name, type: String
  field :department_id, type: String

  field :recipient, type: String
  field :recipient_mobile, type: String
  field :patient_identifier, type: String
  field :patient_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :store_name, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :canceled_by, type: String
  field :is_canceled, type: Boolean, default: false
  field :cancel_date, type: Date
  field :refund_reason, type: String
  
  field :is_migrated, type: Boolean, default: false

  field :mode_of_payment, type: String, default: 'Cash'

  field :card_number, type: String
  field :card_transaction_note, type: String
  field :paytm_transaction_id, type: String
  field :paytm_transaction_note, type: String
  field :gpay_transaction_id, type: String
  field :gpay_transaction_note, type: String
  field :phonepe_transaction_id, type: String
  field :phonepe_transaction_note, type: String
  field :transfer_date, type: Date
  field :transfer_note, type: String
  field :cheque_date, type: Date
  field :cheque_note, type: String
  field :other_transaction_id, type: String
  field :other_note, type: String
           
  field :is_refunded, type: Boolean, default: true
  field :is_canceled, type: Boolean, default: false

  field :srn_id, type: BSON::ObjectId # Id to keep track of srn

  field :order_id, type: BSON::ObjectId
  field :bkp_return_bill_number, type: String

  embeds_many :items, class_name: '::Inventory::Transaction::Item'
  embeds_many :sequences, class_name: '::Inventory::Transaction::Return::Sequence'

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  def self.build(*args)
    refund = new
    refund.items.build(*args)
    refund
  end
end

# db.inventory_transaction_returns.createIndex({"invoice_id": 1 });
# db.inventory_transaction_returns.createIndex({"created_at": 1, "organisation_id": 1 });
# db.inventory_transaction_returns.createIndex({"updated_at": 1, "organisation_id": 1 });