class Inventory::StoreConversionStatistic
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

  field :advised_on, type: Date
  # field :converted_on, type: Date

  # field :advised_by_id, type: BSON::ObjectId
  # field :advised_by_name, type: String

  # field :converted_by_id, type: BSON::ObjectId
  # field :converted_by_name, type: String

  # field :converted_at_store_id, type: BSON::ObjectId
  # field :converted_at_store_name, type: String

  field :total_advised, type: Integer
  field :total_converted, type: Integer

  field :conversion_in_days, type: Float
  field :conversion_in_percentage, type: Float

  field :is_migrated, type: Boolean, default: true

  field :filter_fields, type: Hash
  field :search_fields, type: Hash
end

# db.inventory_store_conversion_statistics.createIndex({"filter_fields.advised_on_date": 1, "filter_fields.facility_id": 1, "filter_fields.department_id": 1})