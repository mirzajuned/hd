class Inventory::Transaction::Purchase
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend Enumerize

  field :variant_count, type: Integer

  field :total_cost, type: Float
  field :mode_of_payment, type: String
  field :discount, type: Float
  field :net_amount, type: Float
  field :amount_paid, type: Float
  field :amount_remaining, type: Float
  field :credit_adjustment, type: Float
  field :debit_amount, type: Float # Amount after purchase return from store to vendor
  field :comments, type: String
  field :payment_completed, type: Boolean, default: false
  field :extra_amount_paid, type: Float # Amount paid other than debit amount

  field :transaction_date, type: Date
  field :transaction_time, type: Time
  field :note, type: String

  field :entered_by, type: String
  field :entry_type, type: String # opening_stock, transaction

  field :is_deleted, type: Boolean, default: false

  field :vendor_id, type: BSON::ObjectId
  field :vendor_name, type: String
  field :vendor_address, type: String
  field :vendor_location_id, type: BSON::ObjectId
  field :vendor_location_name, type: String
  field :vendor_location_address, type: String
  field :vendor_gst_number, type: String
  field :store_gst_number, type: String
  field :vendor_dl_number, type: String

  field :purchase_order_ids, type: Array, default: []
  field :purchase_order_id, type: BSON::ObjectId

  field :purchase_display_id # to display unique id for each transaction
  field :bkp_purchase_display_id

  field :tax_breakup, type: Array, default: []
  field :purchase_taxable_amount, type: Float # Total taxable amount

  field :department_id, type: String
  field :department_name, type: String

  field :challan_number, type: String
  field :challan_date, type: Date
  field :bill_number, type: String
  field :bill_date, type: Date
  field :bill_type, type: Integer #enum

  field :user_id, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :cancelled_by_id, type: BSON::ObjectId
  field :cancelled_by_name, type: String
  field :cancelled_on, type: DateTime
  field :cancelled_reason, type: String

  field :approved_by_id, type: BSON::ObjectId
  field :approved_by_name, type: String
  field :approved_on, type: DateTime
  field :approved_reason, type: String
  field :status, type: Integer

  # other charges field
  # field :other_charges, type: Array, default: []
  field :total_other_charges_amount, type: Float
  field :total_paid_stock, type: Float
  field :tax_amount, type: Float
  field :version, type: String
  field :po_display_id, type: String

  field :is_purchase_bill_created, type: Boolean, default: false
  field :is_purchase_bill_approved, type: Boolean, default: false
  field :is_purchase_bill_cancelled, type: Boolean, default: false
  field :purchase_bill_created_by, type: BSON::ObjectId
  field :purchase_bill_created_by_name, type: String
  field :purchase_bill_created_on, type: DateTime
  field :purchase_bill_approved_by, type: BSON::ObjectId
  field :purchase_bill_approved_by_name, type: String
  field :purchase_bill_approved_on, type: DateTime



  # this id will be present only in case of requisition through optical order
  field :optical_order_id, type: BSON::ObjectId
  field :requisition_order_id, type: BSON::ObjectId

  enumerize :status, in: { open: 0, approved: 1, cancelled: 2, completed: 3 }, default: :open, predicates: true
  enumerize :bill_type, in: { bill: 0, challan: 1}, predicates: { prefix: true }

  embeds_many :items, class_name: '::Inventory::Transaction::Item'
  embeds_many :payment_received_breakups, class_name: '::Invoice::PaymentReceivedBreakup'
  embeds_many :other_charges, class_name: '::Inventory::Transaction::OtherCharge'
  embeds_many :sequences, class_name: '::Inventory::Transaction::Purchase::Sequence'

  belongs_to :store, class_name: '::Inventory::Store', optional: true
  belongs_to :vendor, class_name: '::Inventory::Vendor', optional: true
  belongs_to :cancelled_by, class_name: '::User', optional: true, foreign_key: :cancelled_by_id
  belongs_to :approved_by, class_name: '::User', optional: true, foreign_key: :approved_by_id

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :payment_received_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 },
                                allow_destroy: true

  accepts_nested_attributes_for :other_charges,
                                reject_if: proc { |attributes| attributes['name'].blank? },
                                allow_destroy: true

  def self.build(*args)
    purchase = new
    purchase.items.build(*args)
    purchase
  end

  def self.build_with_order(order_items)
    purchase = new
    order_items.each do |item|
      purchase.items.build(item.attributes)
    end
    purchase
  end

  [:cancelled, :approved].each do |method|
    define_method "set_#{method}" do |user, reason|
      self.update( status: method, "#{method}_by_id": user.id,
        "#{method}_by_name": user.fullname, "#{method}_on": DateTime.now, "#{method}_reason": reason)
    end
  end

end
