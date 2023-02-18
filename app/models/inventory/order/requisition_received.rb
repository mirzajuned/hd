class Inventory::Order::RequisitionReceived
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :requisition_order_date, type: Date
  field :requisition_order_time, type: Time

  field :status, type: String, default: 'Pending'

  field :remarks, type: String
  field :requisition_received_display_id, type: String
  field :requisition_display_id, type: String
  field :requisition_type, type: String # Urgent, Normal, Auto, Semi-auto
  field :created_from, type: String # System, Manual

  field :entered_by, type: String
  field :entry_type, type: String

  field :is_deleted, type: Boolean, default: false
  field :is_active, type: Boolean, default: true

  field :requisition_approved_date, type: Date # (after approve)
  field :requisition_approved_time, type: Time # (after approve)
  field :requisition_order_id, type: BSON::ObjectId
  field :requisition_order_created_by_id, type: BSON::ObjectId
  field :requisition_order_created_by_name, type: String
  field :requisition_order_store_name, type: BSON::ObjectId # transferring store id
  field :requisition_order_store_id, type: BSON::ObjectId # transferring store id
  field :requisition_order_department_name, type: String
  field :requisition_order_department_id, type: String
  field :requisition_order_approved_by_id, type: BSON::ObjectId
  field :requisition_order_approved_by_name, type: String
  field :requisition_created_at, type: Time # Time at which requisition has been created

  # field :requisition_id, type: BSON::ObjectId

  field :user_id, type: BSON::ObjectId
  field :store_name, type: BSON::ObjectId # receiving store/department id
  field :store_id, type: BSON::ObjectId # receiving store/department id
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :closed_reason, type: String
  field :closed_by_id, type: BSON::ObjectId
  field :closed_date_time, type: Time
  field :closed_by, type: String

  field :vendor_id, type: BSON::ObjectId
  field :optical_order_id, type: BSON::ObjectId

  embeds_many :items, class_name: '::Inventory::Order::Item'
  has_many :transfers, class_name: '::Inventory::Transaction::Transfer',
           foreign_key: :requisition_received_id, inverse_of: :requisition_received

  accepts_nested_attributes_for :items,
                                 reject_if: proc { |attributes| attributes['stock'].blank? },
                                 allow_destroy: true
end
