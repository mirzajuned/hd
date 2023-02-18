class Inpatient::BillOfMaterial
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend SearchType
  
  validates_presence_of :facility_id, :admission_id, :patient_id

  field :patient_name, type: String
  field :patient_id, type: BSON::ObjectId
  field :admission_id, type: BSON::ObjectId
  field :tray_display_id, type: String

  field :entry_type, type: String
  field :bom_display_id, type: String
  field :note, type: String
  field :transaction_date, type: Date, default: Date.current
  field :transaction_time, type: Time, default: Time.current
  field :checkout_date, type: Date
  field :checkout_time, type: Time
  field :tray_ids, type: Array # To store all tray id for a particular BOM

  field :total_cost, type: Float
  field :discount, type: Float
  field :total_billing_price, type: Float
  field :billable, type: Boolean, default: false

  field :is_billed, type: Boolean, default: false # To check particular BOM has been billed in Invoice
  field :ipd_invoice_id, type: BSON::ObjectId
  field :ipd_invoice_date, type: Date
  field :ipd_invoice_time, type: Time
  field :operative_note_id, type: BSON::ObjectId
  field :used_in_operative_note, type: Boolean, default: false # To check particular BOM has been consumed in Operative Note
  field :operative_note_date, type: Date
  field :operative_note_time, type: Time

  field :canceled_by, type: String
  field :canceled_by_id, type: BSON::ObjectId
  field :is_canceled, type: Boolean, default: false
  field :cancel_date, type: Date
  field :search_type, type: String
  field :is_edited, type: Boolean, default: false
  field :is_active, type: Boolean, default: false

  field :admission_date, type: DateTime
  field :admitting_doctor, type: String
  field :payer_master_id, type: String

  field :store_name, type: String
  field :department_name, type: String
  field :department_id, type: String
  field :user_id, type: BSON::ObjectId
  field :entered_by, type: String
  field :user_name, type: String
  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  embeds_many :items, class_name: '::Inpatient::BomItem'

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank

  def self.build(*args)
    bom = new
    bom.items.build(*args)
    bom
  end
end
