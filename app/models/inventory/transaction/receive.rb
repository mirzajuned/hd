class Inventory::Transaction::Receive
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :variant_count, type: Integer

  field :total_cost, type: Float

  field :transaction_date, type: Date
  field :transaction_time, type: Time

  field :status, type: String, default: 'Pending' # Pending, Cancelled, Partially Received, Received

  field :note, type: String
  field :transfer_note, type: String

  field :entered_by, type: String
  field :entry_type, type: String # opening_stock, transaction

  field :is_deleted, type: Boolean, default: false

  field :receive_display_id, type: String # Unique Receive display Id

  field :transfer_date, type: Date
  field :transfer_time, type: Time
  field :transfer_order_id, type: BSON::ObjectId # indent, request or order from transferring store/department
  field :transfer_user_id, type: BSON::ObjectId
  field :transfer_user_name, type: String
  field :transfer_id, type: BSON::ObjectId
  field :transfer_store_id, type: BSON::ObjectId # transferring store id
  field :transfer_store_name, type: BSON::ObjectId # transferring store id
  field :transfer_department_name, type: String
  field :transfer_department_id, type: String

  field :user_id, type: BSON::ObjectId
  field :store_name, type: BSON::ObjectId # receiving store/department id
  field :store_id, type: BSON::ObjectId # receiving store/department id
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :requisition_display_id, type: String
  field :requisition_id, type: BSON::ObjectId
  field :requisition_received_id, type: BSON::ObjectId

  # this id will be present only in case of requisition through optical order
  field :optical_order_id, type: BSON::ObjectId
  field :requisition_order_id, type: BSON::ObjectId

  embeds_many :items, class_name: '::Inventory::Transaction::Item'

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  def self.build(*args)
    receive = new
    receive.items.build(*args)
    receive
  end
end
