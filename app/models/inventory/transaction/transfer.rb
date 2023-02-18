class Inventory::Transaction::Transfer
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend SearchType
  extend Enumerize

  field :variant_count, type: Integer

  field :total_cost, type: Float

  field :transaction_date, type: Date
  field :transaction_time, type: Time

  field :transfer_display_id, type: String # Unique Id for each transaction
  field :issue_display_id, type: String 

  #field :status, type: String, default: 'In-process' # Draft, In-process, Cancelled, Closed

  #field :receive_status, type: String, default: 'Pending' # Pending, Cancelled, Partially Received, Received

  field :note, type: String

  field :type, type: String, default: 'facility_store' # Transfer type to facility store or central hub
  field :search_type, type: String
  field :entered_by, type: String
  field :entry_type, type: String # transfer

  field :is_deleted, type: Boolean, default: false

  field :transfer_order_id, type: BSON::ObjectId # indent, request or order from receiving store/department
  field :transfer_type, type: String

  field :department_id, type: String
  field :department_name, type: String

  field :user_id, type: BSON::ObjectId

  field :receive_id, type: BSON::ObjectId
  field :receive_store_id, type: BSON::ObjectId # receiving store/department id
  field :receive_store_name, type: BSON::ObjectId # receiving store/department id
  field :receive_facility_id, type: BSON::ObjectId # In case of central Hub
  field :receive_facility_name, type: BSON::ObjectId # In case of central Hub

  field :store_id, type: BSON::ObjectId # transferring store id
  field :store_name, type: BSON::ObjectId # transferring store id
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :cancelled_by_id, type: BSON::ObjectId
  field :cancelled_by_name, type: String
  field :cancelled_on, type: DateTime

  field :approved_by_id, type: BSON::ObjectId
  field :approved_by_name, type: String
  field :approved_on, type: DateTime

  field :closed_by_id, type: BSON::ObjectId
  field :closed_by_name, type: String
  field :closed_on, type: DateTime

  field :status, type: Integer
  field :receive_status, type: Integer
  field :requisition_received_id, type: BSON::ObjectId
  field :requisition_id, type: BSON::ObjectId
  field :transfer_from, type: String  #transfer from requisition or normal transfer
  field :is_missing_stock_available, type: Boolean, default: false

  # this id will be present only in case of requisition through optical order
  field :optical_order_id, type: BSON::ObjectId
  # fields related to tax invoice
  field :is_tax_invoice_created, type: Boolean, default: false
  field :tax_invoice_created_by, type: BSON::ObjectId
  field :tax_invoice_created_on, type: Time

  field :is_tax_invoice_cancelled, type: Boolean, default: false
  field :tax_invoice_cancelled_by, type: BSON::ObjectId
  field :tax_invoice_cancelled_on, type: Time

  field :tax_invoice_approved_on, type: Time
  field :is_tax_invoice_approved, type: Boolean, default: false
  field :tax_invoice_approved_by, type: BSON::ObjectId

  # fields related to delivery challan
  field :is_delivery_challan_created, type: Boolean, default: false
  field :delivery_challan_created_by, type: BSON::ObjectId
  field :delivery_challan_created_on, type: Time

  field :is_delivery_challan_cancelled, type: Boolean, default: false
  field :delivery_challan_cancelled_by, type: BSON::ObjectId
  field :delivery_challan_cancelled_on, type: Time

  field :delivery_challan_approved_on, type: Time
  field :is_delivery_challan_approved, type: Boolean, default: false
  field :delivery_challan_approved_by, type: BSON::ObjectId
  # Inventory::Transaction::Transfer.update_all(is_tax_invoice_created: false, is_delivery_challan_created: false)

  enumerize :status,
            in: { open: 0, approved: 1, cancelled: 2, inprocess: 3, completed: 4, pending: 5, closed: 6 },
            default: :open, predicates: true, scope: :having_status
  #eg. having_status => Inventory::Transaction::Transfer.having_status(:inprocess)

  enumerize :receive_status,
            in: { none: 0, cancelled: 1, partially_received: 2, completed: 3 },
            default: :none

  embeds_many :items, class_name: '::Inventory::Transaction::Item'

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  belongs_to :store, optional: true, class_name: '::Inventory::Store'
  belongs_to :approved_by, optional: true, class_name: '::User'
  belongs_to :requisition_received, optional: true,
             class_name: '::Inventory::Order::RequisitionReceived', inverse_of: :transfers

  def self.build(*args)
    transfer = new
    transfer.items.build(*args)
    transfer
  end

  [:cancelled, :approved, :closed].each do |method|
    define_method "set_#{method}" do |user|
      self.update( status: method, "#{method}_by_id": user.id,
        "#{method}_by_name": user.fullname, "#{method}_on": DateTime.now )
    end
  end
end