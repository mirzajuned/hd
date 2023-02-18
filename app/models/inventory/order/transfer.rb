class Inventory::Order::Transfer # Indent from other department
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :vendor_name, type: String

  field :variant_count, type: Integer

  field :total_cost, type: Float

  field :transaction_date, type: Date

  field :status, type: String, default: 'In-process' # Draft, In-process, Cancelled, Closed

  field :receive_status, type: String, default: 'Open' # Open, Cancelled, Incomplete, Completed

  field :note, type: String

  field :entered_by, type: String
  field :entry_type, type: String # opening_stock, transaction

  field :is_deleted, type: Boolean, default: false

  field :vendor_id, type: BSON::ObjectId # vendor of transferring store

  field :user_id, type: BSON::ObjectId

  field :receive_id, type: BSON::ObjectId
  field :receive_store_name, type: BSON::ObjectId
  field :receive_store_id, type: BSON::ObjectId # receiving store/department id
  field :store_id, type: BSON::ObjectId # transferring store id

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  embeds_many :items, class_name: '::Inventory::Transaction::Item'

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  def self.build(*args)
    purchase = new
    purchase.items.build(*args)
    purchase
  end
end
