class Inventory::Order::Indent::Sequence
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sequence_id, type: BSON::ObjectId
  field :display_format, type: BSON::ObjectId
  field :is_primary, type: Boolean, default: false
  field :is_active, type: Boolean, default: false

  field :date, type: Date
  field :time, type: Time
  
  embedded_in :inventory_order_indent
end
