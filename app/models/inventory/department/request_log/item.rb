class Inventory::Department::RequestLog::Item
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :quantity, type: String

  belongs_to :inventory_item, optional: true, class_name: '::Inventory::Item'
  embedded_in :request_log, class_name: '::Inventory::Department::RequestLog'
end
