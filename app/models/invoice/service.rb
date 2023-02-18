class Invoice::Service
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :label, type: String
  field :description, type: String
  field :service_code, type: String
  field :entry_type, type: String
  #entry_type :: 'surgery_package' => surgery_package_id (SurgeryPackage)
  #entry_type :: 'service' => pricing_master_id (PricingMaster)
  #entry_type :: 'bill_of_material' => bill_of_material_id (Inpatient::BillOfMaterial)

  field :unit_price, type: Float
  field :total_units, type: Integer

  field :is_advance, type: String, default: 'N'

  # Added For Ins.
  field :name, type: String
  field :service_total, type: Float

  # Service Master
  # field :description, type: String #commented on 2020-05-04, duplicate
  # field :unit_price, type: Float #commented on 2020-05-04, duplicate
  field :quantity, type: Integer
  field :price, type: Float
  field :item_entry_date, type: Time
  field :patient_payed, type: String
  field :doctor_id, type: BSON::ObjectId
  field :exception_id, type: String

  # Tax Enabled
  field :tax_group_id, type: BSON::ObjectId
  field :tax_inclusive, type: Boolean, default: false
  field :non_taxable_amount, type: Float, default: 0.00
  field :taxable_amount, type: Float, default: 0.00
  field :tax_group, type: Array, default: []
  # Service Master ends

  # discount related fields for invoice
  field :net_item_price, type: Float
  field :discount_amount, type: Float, default: 0
  field :discount_percentage, type: Float, default: 0
  field :discount_reason, type: String
  field :show_breakup_in_print, type: Boolean, default: false

  # added service type
  field :service_type, type: String
  field :consultant_user_id, type: String

  # Offer related fields
  field :offer_manager_id, type: BSON::ObjectId
  field :offer_name, type: String
  field :offer_code, type: String
  field :offer_percentage, type: Integer
  field :offer_amount, type: Float, default: 0.00

  field :offer_applied_at, type: BSON::ObjectId # facility
  field :offer_applied_at_name, type: String
  field :offer_applied_by, type: BSON::ObjectId
  field :offer_applied_by_name, type: String
  field :offer_applied_date, type: Date
  field :offer_applied_datetime, type: Time

  belongs_to :service, optional: true, class_name: '::Service'

  embeds_many :items, class_name: '::Invoice::Service::Item'
  embedded_in :invoice, class_name: '::Invoice'
  embedded_in :finance_report_data, class_name: '::Finance::ReportData'
end
