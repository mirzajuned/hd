class Inventory::Transaction::VendorReturn
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :purchase_return_id, type: String
  field :bkp_purchase_return_id, type: String

  field :transaction_date, type: Date
  field :transaction_time, type: Time
  field :purchase_transaction_id, type: BSON::ObjectId
  field :transaction_ids, type: Array, default: []

  field :status, type: String, default: 'Completed'
  field :note, type: String

  field :entered_by, type: String
  field :entry_type, type: String
  field :return_type, type: String

  field :total_cost, type: Float
  field :return_discount, type: Float
  field :return_amount, type: Float
  field :paid_amount, type: Float
  field :debit_amount, type: Float
  field :mode_of_payment, type: String
  field :comments, type: String
  field :full_settlement, type: Boolean, default: true

  field :department_name, type: String
  field :department_id, type: String

  field :user_id, type: BSON::ObjectId
  field :store_name, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :vendor_mobile, type: String
  field :vendor_id, type: BSON::ObjectId
  field :vendor_name, type: String
  field :vendor_address, type: String
  field :vendor_location_id, type: BSON::ObjectId
  field :vendor_location_name, type: String
  field :vendor_location_address, type: String
  field :vendor_gst_number, type: String
  field :vendor_dl_number, type: String
  field :store_gst_number, type: String

  embeds_many :items, class_name: '::Inventory::Transaction::Item'
  embeds_many :payment_received_breakups, class_name: '::Invoice::PaymentReceivedBreakup'
  embeds_many :sequences, class_name: '::Inventory::Transaction::VendorReturn::Sequence'

  accepts_nested_attributes_for :payment_received_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 },
                                allow_destroy: true

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  def self.build(*args)
    refund = new
    refund.items.build(*args)
    refund
  end
end
