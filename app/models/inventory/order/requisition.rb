class Inventory::Order::Requisition
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # fields taken from document
  field :requisition_display_id, type: String
  field :requisition_date_time, type: Time
  field :requisition_creation_time, type: Time
  field :requisition_date, type: Date
  field :requisition_type, type: String # Urgent, Normal, Auto, Semi-auto
  field :created_from, type: String # System, Manual
  field :category_ids, type: Array, default: []
  field :remarks, type: String
  field :requisition_time

  field :store_id, type: BSON::ObjectId # store from which requisition will be made
  field :store_name, type: String
  field :receive_store_id, type: BSON::ObjectId # store for which requisition will be made
  field :receive_store_name, type: String

  field :status, type: String # status to check requisition has been approved or not
  field :cancelled_reason, type: String
  field :cancelled_by, type: String
  field :cancelled_date_time, type: Time
  field :receive_status, type: String, default: 'Pending' # Pending, Cancelled, Partially Received, Received

  field :search_type, type: String

  field :is_active, type: Boolean, default: true
  field :is_disabled, type: Boolean, default: false
  field :department_id, type: String
  field :department_name, type: String

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :entered_by, type: String
  field :entered_by_id, type: BSON::ObjectId

  field :approved_by, type: String
  field :approved_by_id, type: BSON::ObjectId
  field :approved_date_time, type: Time

  field :closed_reason, type: String
  field :closed_by_id, type: BSON::ObjectId
  field :closed_date_time, type: Time
  field :closed_by, type: String

  field :optical_order_id, type: BSON::ObjectId
  field :request_from, type: String
  field :vendor_id, type: BSON::ObjectId
  field :fulfilment_status, type: String

  validates_presence_of :store_id, :receive_store_id

  embeds_many :items, class_name: '::Inventory::Order::Item'

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  def self.build(*args)
    requisition = new
    requisition.items.build(*args)
    requisition
  end
end
