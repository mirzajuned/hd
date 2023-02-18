class Inventory::History::LotBlocked
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend Enumerize

  field :lot_id, 				  type: BSON::ObjectId
  field :item_id,				  type: BSON::ObjectId
  field :transaction_id,          type: BSON::ObjectId
  field :transaction_type,        type: String          #transaction class name
  field :quantity, 				  type: Integer
  field :entered_by_id,			  type: BSON::ObjectId
  field :approved_by_id,		  type: BSON::ObjectId
  field :entered_by_name,	      type: String
  field :approved_by_name,        type: String
  field :created_on,              type: DateTime
  field :approved_on,             type: DateTime
  field :cancelled_on,            type: DateTime
  field :variant_id,              type: BSON::ObjectId
  field :store_id,                type: BSON::ObjectId
  field :facility_id,             type: BSON::ObjectId
  field :organisation_id,         type: BSON::ObjectId
  field :status,                  type: Integer

  enumerize :status, in: { open: 0, closed: 1, cancelled: 2 }, default: :open, predicates: true 

  belongs_to :lot,         optional: true, class_name: '::Inventory::Item::Lot'
  belongs_to :item,        optional: true, class_name: '::Inventory::Transaction::Item'
  belongs_to :item,        optional: true, class_name: '::Invoice::InventoryItem'
  belongs_to :entered_by,  optional: true, class_name: '::User'
  belongs_to :approved_by, optional: true, class_name: '::User'

  def self.cancel_all
    update_all(status: status.cancelled.value)
  end

end