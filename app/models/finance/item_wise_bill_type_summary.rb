class Finance::ItemWiseBillTypeSummary
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

  field :invoice_id, type: BSON::ObjectId
  field :item_id, type: BSON::ObjectId
  field :item_entry_date, type: Date
  field :item_entry_datetime, type: DateTime

  field :bill_type, type: String # free/paid/discounted
  field :bill_entry_type, type: String # surgery_package/service/bill_of_material
  field :bill_entry_type_id, type: String # description field in invoice.services

  # fields for procedure wise report
  field :service_type, type: String # procedure(446308005)/radiology/ophthal
  field :service_type_code, type: String
  # name of the procedure/radiology/ophthal
  field :service_type_code_name, type: String

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

  field :is_migrated, type: Boolean, default: true
  
  validates :item_id, uniqueness: true, if: -> { item_id.present? }
end

# ------------- Indexes to create data 
# db.invoice.createIndex({"services.item_entry_date": 1, "organisation_id": 1, "is_migrated": 1 }, {name:"idxformigration_create_service_summary"});

# db.finance_item_wise_bill_type_summaries.createIndex({"service_id": 1, "invoice_id": 1, "facility_id": 1, "department_id": 1 }, {name:"idxformigration_create_service_summary"});
# ------------- Indexes to create data 

# db.finance_item_wise_bill_type_summaries.createIndex({"item_entry_datetime": -1, "facility_id": 1, "bill_type": 1 }, {name:"date_item_wise_bill_type_indexes"});

