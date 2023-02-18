class Inventory::Department::RequestLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :department, type: String
  field :note, type: String
  field :status, type: Integer, default: -1 #-1 = incomplete, 0 = half complete, 1 = complete, 2 = deleted
  belongs_to :facility, class_name: '::Facility'
  embeds_many :items, class_name: '::Inventory::Department::RequestLog::Item'
end
