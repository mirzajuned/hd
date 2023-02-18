class Inventory::DailyLotStock
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :date, type: Date
  field :time, type: Time

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :department_id, type: String

  embeds_many :daily_lot_data, class_name: '::Inventory::DailyLotData'
end
