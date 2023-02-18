class Inventory::Transaction::StockReceiveNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend Enumerize

  field :variant_count,     type: Integer
  field :total_cost,        type: Float
  field :mode_of_payment,   type: String
  field :discount,          type: Float
  field :net_amount,        type: Float
  field :amount_paid,       type: Float, default: 0.0
  field :amount_remaining,  type: Float
  field :credit_adjustment, type: Float
  field :debit_amount,      type: Float # Amount after srn return from store to vendor
  field :comments,          type: String
  field :payment_completed, type: Boolean, default: true
  field :extra_amount_paid, type: Float # Amount paid other than debit amount
  field :transaction_date,  type: Date
  field :transaction_time,  type: Time
  field :note,              type: String
  field :entered_by,        type: String
  field :entry_type,        type: String # opening_stock, transaction
  field :is_deleted,        type: Boolean, default: false
  field :tax_breakup,       type: Array, default: []
  field :taxable_amount,    type: Float # Total taxable amount
  field :department_id,     type: String
  field :department_name,   type: String
  field :document_number,    type: String
  field :user_id,           type: BSON::ObjectId
  field :store_id,          type: BSON::ObjectId
  field :facility_id,       type: BSON::ObjectId
  field :organisation_id,   type: BSON::ObjectId
  field :cancelled_by_id,   type: BSON::ObjectId
  field :cancelled_by_name, type: String
  field :cancelled_on,      type: DateTime
  field :approved_by_id,    type: BSON::ObjectId
  field :approved_by_name,  type: String
  field :approved_on,       type: DateTime
  field :status,            type: Integer
  field :type,              type: Integer
  field :srn_display_id,    type: String
  field :vendor_name,       type: String
  field :vendor_id,         type: BSON::ObjectId
  field :vendor_location_id,type: BSON::ObjectId
  # field :other_charges,     type: Array, default: []
  field :total_other_charges_amount, type: Float

  field :order_id,          type: BSON::ObjectId

  field :challan_number, type: String
  field :challan_date, type: Date
  field :bill_number, type: String
  field :bill_date, type: Date
  field :bill_type, type: Integer #enum

  field :bkp_srn_display_id,    type: String

  enumerize :bill_type, in: { bill: 0, challan: 1}, predicates: { prefix: true }

  validates_presence_of :bkp_srn_display_id, message: 'SRN Display Id cannot be blank'

  validates_presence_of :order_id, message: 'Order Id cannot be blank'

  enumerize :status, in: { open: 0, approved: 1, cancelled: 2, completed: 3 },
    default: :open, predicates: { prefix: true }
  enumerize :type, in: { opening: 0, optical: 1, maintenance: 2 },
    default: :opening, predicates: { prefix: true }

  embeds_many :items, class_name: '::Inventory::Transaction::Item'
  embeds_many :payment_received_breakups, class_name: '::Invoice::PaymentReceivedBreakup'
  embeds_many :other_charges, class_name: '::Inventory::Transaction::OtherCharge'
  embeds_many :sequences, class_name: '::Inventory::Transaction::StockReceiveNote::Sequence'

  belongs_to :store, class_name: '::Inventory::Store', optional: true
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
    stock_receive = new
    stock_receive.items.build(*args)
    stock_receive
  end

  [:cancelled, :approved].each do |method|
    define_method "set_#{method}" do |user|
      self.update( status: method, "#{method}_by_id": user.id,
        "#{method}_by_name": user.fullname, "#{method}_on": DateTime.now )
    end
  end

end

