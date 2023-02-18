class Inventory::Order::Purchase
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend Enumerize

  field :variant_count, type: Integer

  field :total_cost, type: Float
  field :discount, type: Float
  field :net_amount, type: Float

  field :comments, type: String

  field :is_completed, type: Boolean, default: false   # Order is fulfilled Completely, No further action required
  field :is_closed, type: Boolean, default: false      # No further action required
  field :transaction_present, type: Boolean, default: false # Completed,  # Partially-Completed
  field :is_cancelled, type: Boolean, default: false        # Cancelled

  field :order_date, type: Date
  field :estimated_delivery_date, type: Date
  field :delivery_date, type: Date
  field :order_date_time, type: Time

  field :note, type: String

  field :order_status, type: String, default: 'Pending' # Pending, Completed, Partially-Completed, Cancelled

  field :entered_by, type: String
  field :entry_type, type: String # opening_stock, transaction

  field :is_deleted, type: Boolean, default: false

  field :purchase_transaction_ids, type: Array, default: []

  field :purchase_display_id, type: String # Display unique id for each transaction

  field :tax_breakup, type: Array, default: []
  field :purchase_taxable_amount, type: Float # Total taxable amount

  field :department_id, type: String
  field :department_name, type: String

  field :indent_id, type: BSON::ObjectId

  field :user_id, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :store_name, type: String
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  # field :other_charges,     type: Array, default: []
  field :total_other_charges_amount, type: Float
  field :remaining_total_other_charges_amount, type: Float
  field :po_type, type: String
  field :tax_amount, type: Float

  field :payment_terms,     type: Array, default: []
  field :delivery_terms,     type: Array, default: []

  field :ship_to_store, type: BSON::ObjectId
  field :bill_to_store, type: BSON::ObjectId
  field :bill_to_address, type: Hash, default: {}
  field :ship_to_address, type: Hash, default: {}

  field :po_expiry_date, type: Date
  field :version, type: String

  field :vendor_id, type: BSON::ObjectId
  field :vendor_name, type: String
  field :vendor_address, type: String
  field :vendor_location_id, type: BSON::ObjectId
  field :vendor_location_name, type: String
  field :vendor_location_address, type: String
  field :vendor_credit_days, type: Integer
  field :vendor_gst_number, type: String
  field :store_gst, type: String

  field :approved_by, type: BSON::ObjectId
  field :approved_by_name, type: String
  field :approved_date_time, type: Time
  field :approved_reason, type: String

  field :cancelled_by, type: BSON::ObjectId
  field :cancelled_by_name, type: String
  field :cancelled_date_time, type: DateTime
  field :cancelled_reason, type: String

  field :closed_by, type: BSON::ObjectId
  field :closed_by_name, type: String
  field :closed_date_time, type: DateTime
  field :closed_reason, type: String
  field :create_from, type: BSON::ObjectId # store for which Indent will be made
  field :create_store_name, type: String

  # this id will be present only in case of requisition through optical order
  field :optical_order_id, type: BSON::ObjectId
  field :requisition_order_id, type: BSON::ObjectId
  field :created_from_optical_order, type: Boolean, default: false
  field :email_delivered, type: Boolean, default: false

  field :global_discount, type: Float
  field :hdn_global_discount, type: Float
  field :global_discount_type, type: String

  field :po_total_paid_stock, type: Float
  field :remaining_po_total_paid_stock, type: Float

  embeds_many :items, class_name: '::Inventory::Order::Item'
  embeds_many :other_charges, class_name: '::Inventory::Transaction::OtherCharge'

  # Pending, Completed, Partially-Completed, Cancelled
  enumerize :order_status, in: { pending: "Pending", approved: "Approved", cancelled: "Cancelled", completed: "Completed",partially_completed: "Partially-Completed", closed: 'Closed' }, default: :pending, predicates: true
  belongs_to :cancelled_by_id, class_name: '::User', optional: true, foreign_key: :cancelled_by
  belongs_to :approved_by_id, class_name: '::User', optional: true, foreign_key: :approved_by
  belongs_to :closed_by_id, class_name: '::User', optional: true, foreign_key: :closed_by
  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :other_charges,
                                reject_if: proc { |attributes| attributes['name'].blank? },
                                allow_destroy: true

  def self.build(*args)
    purchase = new
    purchase.items.build(*args)
    purchase
  end

  def self.build_with_indent(indent_items)
    purchase = new
    indent_items.each do |item|
      purchase.items.build(item.attributes)
    end
    purchase
  end

  [:cancelled, :approved, :closed].each do |method|
    define_method "set_#{method}" do |user, reason|
      self.update( order_status: method, "#{method}_by": user.id,
        "#{method}_by_name": user.fullname, "#{method}_date_time": DateTime.now, "#{method}_reason": reason)
    end
  end

  scope :is_completed, -> { where(order_completed: true) }
  scope :is_partially_completed, -> { where(order_completed: false, transaction_present: true) }
  validates :purchase_display_id, presence: true
end
