class Inpatient::Bom
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :item_code, type: String
  field :variant_code, type: String
  field :category, type: String
  field :description, type: String

  field :batch_no, type: String
  field :total_cost, type: Float
  field :unit_cost, type: Float # renamed from price
  field :list_price, type: Float
  field :total_list_price, type: Float
  field :expiry, type: Date
  field :quantity, type: Integer
  field :item_id, type: BSON::ObjectId
  field :variant_id, type: BSON::ObjectId
  field :bom_list_price, type: Float
  field :bom_quantity, type: Integer
  field :tray_id, type: BSON::ObjectId
  field :tray_item_id, type: BSON::ObjectId
  field :billable, type: Boolean, default: false
  field :lot_id, type: String
  field :is_print, type: Boolean, default: false
  field :bom_id, type: BSON::ObjectId
  field :date, type: Date, default: Date.current
  field :time, type: Time, default: Time.current

  field :operative_note_id, type: BSON::ObjectId
  field :type, type: String, default: 'Operative Note'

  embedded_in :ipd_record, class_name: "::Inpatient::IpdRecord"
end
