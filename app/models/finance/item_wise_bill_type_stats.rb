class Finance::ItemWiseBillTypeStats
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :item_entry_date, type: Date
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :facility_timezone, type: String

  field :department_id, type: Integer
  field :department_name, type: String
  field :department_order, type: Integer

  field :bill_type, type: String # free/paid/discounted
  field :service_type, type: String # procedure/radiology/ophthal
  field :service_type_code, type: String
  field :service_type_code_name, type: String

  field :service_group_id, type: BSON::ObjectId
  field :service_group_name, type: String
  field :service_sub_group_id, type: BSON::ObjectId
  field :service_sub_group_name, type: String
  # field :package_group_id, type: String
  # field :package_uniq_id, type: String

  # field :added_by_id, type: BSON::ObjectId
  # field :added_by_name, type: String

  # field :advised_by_id, type: BSON::ObjectId
  # field :advised_by_name, type: String

  field :patient_age_fields, type: Hash
  field :patient_gender_fields, type: Hash
  field :gender_wise_age, type: Hash
end
