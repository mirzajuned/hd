class Inventory::Order::Indent
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :vendor_name, type: String
  field :vendor_id, type: BSON::ObjectId

  field :remarks, type: String

  field :indent_date, type: Date
  field :indent_date_time, type: Time
  field :indent_type, type: String
  field :indent_against_requisition_slip, type: Boolean

  field :is_completed, type: Boolean, default: false   # Order is fulfilled Completely, No further action required
  field :is_closed, type: Boolean, default: false      # No further action required
  field :transaction_present, type: Boolean, default: false # Completed,  # Partially-Completed
  field :is_cancelled, type: Boolean, default: false        # Cancelled
  field :is_deleted, type: Boolean, default: false
  field :status, type: String, default: 'Open'
  field :indent_status, type: String, default: 'Pending' # Pending, Completed, Partially-Completed, Cancelled

  field :created_by, type: String
  field :created_by_id, type: BSON::ObjectId

  field :bkp_indent_display_id, type: String # Display unique id
  field :indent_display_id, type: String # Display unique id

  field :department_id, type: String
  field :department_name, type: String

  field :purchase_order_id, type: BSON::ObjectId
  field :optical_order_id, type: BSON::ObjectId

  field :user_id, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :store_name, type: String
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :requisition_order_id, type: BSON::ObjectId # this id will be present only in case of requisition through optical order
  field :purchase_order_id, type: BSON::ObjectId
  field :create_from, type: BSON::ObjectId # store for which Indent will be made
  field :create_store_name, type: String

  embeds_many :items, class_name: '::Inventory::Order::Item'
  embeds_many :sequences, class_name: '::Inventory::Order::Indent::Sequence'

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  def self.build(*args)
    indent = new
    indent.items.build(*args)
    indent
  end
end
