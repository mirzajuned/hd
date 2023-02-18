class Finance::StatisticPackage
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :organisation_id, type: String
  field :facility_id, type: String
  field :facility_name, type: String
  field :receipt_date, type: Date
  field :specialty_id, type: String
  field :specialty_name, type: String
  field :has_specialties, type: Boolean
  field :sub_specialty_id, type: String
  field :sub_specialty_name, type: String
  field :has_sub_specialties, type: Boolean
  field :department_id, type: String
  field :department_name, type: String
  field :department_order, type: Integer
  field :user_id, type: String
  field :user_name, type: String
  field :surgery_package_id, type: String
  field :surgery_package_name, type: String
  field :total_no_of_bills, type: Integer
  field :total_revenue, type: Float

  field :no_of_free_bills, type: Integer
  field :free_bills_revenue, type: Float
  field :no_of_paid_bills, type: Integer
  field :paid_bills_revenue, type: Float
  field :no_of_discounted_bills, type: Integer
  field :discounted_bills_revenue, type: Float

  field :is_migrated, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false

  field :filter_fields, type: Hash
  field :search_fields, type: Hash
end

# Invoice.where('services.entry_type': 'surgery_package').count

# db.finance_statistic_package.createIndex({"receipt_date": -1, "facility_id": 1 });
