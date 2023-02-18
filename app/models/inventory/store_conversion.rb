class Inventory::StoreConversion
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :facility_timezone, type: String

  field :department_id, type: String
  field :department_name, type: String
  field :department_order, type: Integer

  field :store_id, type: BSON::ObjectId
  field :store_name, type: String
  field :store_abbreviation_name, type: String
  field :store_present, type: Boolean, default: false
  
  field :prescription_id, type: BSON::ObjectId
  field :prescription_type, type: String

  field :specialty_id, type: String
  field :specialty_name, type: String

  field :advised_on_date, type: Date
  field :advised_on_datetime, type: DateTime
  field :advised_by_id, type: BSON::ObjectId
  field :advised_by_details, type: Hash

  field :is_converted, type: Boolean
  field :converted_on_date, type: Date
  field :converted_on_datetime, type: DateTime
  field :converted_by_id, type: BSON::ObjectId
  field :converted_by_details, type: Hash

  field :converted_at_store_id, type: BSON::ObjectId
  field :converted_at_store_name, type: String

  field :dispatched_from_store, type: Boolean, default: false

  field :store_comment, type: String
  field :patient_details, type: Hash

  field :invoice_id, type: BSON::ObjectId
  field :invoice_details, type: Hash
  field :advance_details, type: Hash

  field :order_count, type: Integer, default: 0 # count total no. of order for particular prescription
  field :re_converted, type: Boolean, default: false # true if more than one order for same prescription
  field :mark_patient_visited, type: Boolean, default: false
  
  field :conversion_time_days, type: String

  field :is_deleted, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: true

  field :filter_fields, type: Hash
  field :search_fields, type: Hash

  # field for such prescription who has been marked as not converted and later on they are converting same prescription.
  field :not_converted_to_converted, type: Boolean, default: false

  validates :prescription_id, uniqueness: true, if: -> { prescription_id.present? }

  def self.converted(is_converted)
    if is_converted == true
      'Converted'
    elsif is_converted == false
      'Not Converted'
    else
      'Advised'
    end
  end
end

# db.inventory_store_conversions.createIndex({"advised_on_datetime": -1, "filter_fields.facility_id": 1, "filter_fields.department_id": 1 }, {"name": "idxforfilter"});
