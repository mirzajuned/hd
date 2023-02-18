class Inventory::Transaction::Tray
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend SearchType

  field :patient_name, type: String
  field :patient_id, type: BSON::ObjectId
  field :patient_mobile, type: String
  field :admission_id, type: BSON::ObjectId
  field :patient_display_id, type: String

  field :entry_type, type: String
  field :tray_display_id, type: String
  field :note, type: String
  field :transaction_date, type: Date, default: Date.current # Day on which tray has been created
  field :transaction_time, type: Time, default: Time.current # Time on which tray has been created
  field :checkout_date, type: Date # Day on which Bill of material has been created
  field :checkout_time, type: Time # Time on which Bill of material has been created

  field :status, type: String # Consumed, partially Consumed or Not Consumed
  field :total_cost, type: Float

  field :canceled_by, type: String
  field :canceled_by_id, type: BSON::ObjectId
  field :is_canceled, type: Boolean, default: false
  field :cancel_date, type: Date
  field :search_type, type: String
  field :is_edited, type: Boolean, default: false
  field :is_active, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false

  field :is_closed, type: Boolean, default: false
  field :closed_by, type: String
  field :closed_by_id, type: BSON::ObjectId
  field :closed_date, type: Date

  field :admission_date, type: DateTime
  field :admitting_doctor, type: String

  field :store_name, type: String
  field :department_name, type: String
  field :department_id, type: String
  field :user_id, type: BSON::ObjectId
  field :entered_by, type: String
  field :user_name, type: String
  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  embeds_many :items, class_name: '::Inventory::Transaction::Item'

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank

  def self.build(*args)
    tray = new
    tray.items.build(*args)
    tray
  end
end
