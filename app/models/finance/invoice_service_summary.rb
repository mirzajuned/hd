class Finance::InvoiceServiceSummary
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :facility_timezone, type: String

  field :department_id, type: Integer
  field :department_name, type: String
  field :department_order, type: Integer

  field :service_id, type: BSON::ObjectId
  field :service_entry_date, type: Date
  field :service_entry_datetime, type: DateTime
  field :service_name, type: String

  field :total_units, type: Integer
  field :is_advance, type: String, default: 'N'
  field :service_total, type: Float
  field :quantity, type: Integer
  field :price, type: Float

  field :service_unit_price, type: Float #original unit cost of the service
  field :invoice_unit_price, type: Float #unit cost in the invoice
  field :unit_cost_difference, type: Float #invoice unit cost - service unit cost

  # Tax Enabled
  field :tax_group_id, type: BSON::ObjectId
  field :tax_inclusive, type: Boolean, default: false
  field :non_taxable_amount, type: Float, default: 0.00
  field :taxable_amount, type: Float, default: 0.00
  field :tax_group, type: Array, default: []
  
  field :net_item_price, type: Float
  # discount related fields for invoice
  field :discount_amount, type: Float, default: 0
  field :discount_percentage, type: Float, default: 0
  field :discount_reason, type: String

  # offer related fields for invoice
  field :offer_amount, type: Float, default: 0
  field :offer_percentage, type: Float, default: 0
  field :offer_id, type: BSON::ObjectId
  field :offer_name, type: String
  field :offer_code, type: String

  field :percentage_off, type: Float, default: 0 # based on total discount and offer

  field :discount_type, type: String # free/paid/discounted
  field :bill_entry_type, type: String # surgery_package/service/bill_of_material
  field :bill_entry_type_id, type: String # description field in invoice.services

  field :invoice_id, type: BSON::ObjectId
  field :invoice_display_fields, type: Hash

  # fields for procedure wise report
  field :service_type, type: String # procedure(446308005)/radiology/ophthal
  field :service_type_code, type: String
  # name of the procedure/radiology/ophthal
  field :service_type_code_name, type: String

  field :specialty_id, type: String
  field :specialty_name, type: String
  field :sub_specialty_id, type: String
  field :sub_specialty_name, type: String

  field :service_group_id, type: BSON::ObjectId
  field :service_group_name, type: String
  field :service_sub_group_id, type: BSON::ObjectId
  field :service_sub_group_name, type: String
  # Group Id for the Packages with the same Package Definition
  field :package_group_id, type: String
  # Uniq Id for the Package across Facilities
  field :package_uniq_id, type: String
  # end fields for procedure wise report

  field :added_by_id, type: BSON::ObjectId
  field :added_by_display_fields, type: Hash

  field :advised_by_id, type: BSON::ObjectId
  field :advised_by_display_fields, type: Hash

  field :patient_id, type: BSON::ObjectId
  field :patient_display_fields, type: Hash
  field :payer_display_fields, type: Hash

  field :is_migrated, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false
  
  validates :service_id, uniqueness: true, if: -> { service_id.present? }
end

# ------------- Indexes to create data 
# db.invoice.createIndex({"services.item_entry_date": 1, "organisation_id": 1, "is_migrated": 1 }, {name:"idxformigration_create_service_summary"});

# db.finance_invoice_service_summaries.createIndex({"service_id": 1, "invoice_id": 1, "facility_id": 1, "department_id": 1 }, {name:"idxformigration_create_service_summary"});
# ------------- Indexes to create data 
# db.finance_invoice_service_summaries.update( {}, [ { $set: { "percentage_off": "$discount_percentage" } } ], {multi: true, background: true} )