class Finance::StatisticService
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :organisation_id, type: String
  field :facility_id, type: String
  field :receipt_date, type: Date #service_entry_date from level 2
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
  field :service_id, type: String
  field :service_name, type: String
  field :total_no_of_bills, type: Integer
  field :total_revenue, type: Float

  field :no_of_free_bills, type: Integer
  field :free_bills_revenue, type: Float
  field :no_of_paid_bills, type: Integer
  field :paid_bills_revenue, type: Float
  field :no_of_discounted_bills, type: Integer
  field :discounted_bills_revenue, type: Float

  field :is_migrated, type: Boolean, default: true

  field :filter_fields, type: Hash
  field :search_fields, type: Hash

  # type of bills changes
  field :total_discount, type: Float, default: 0
  field :free_billed, type: Integer, default: 0
  field :free_billed_amount, type: Float, default: 0
  field :discouned_billed, type: Integer, default: 0
  field :discouned_billed_amount, type: Float, default: 0
  field :paid_billed, type: Integer, default: 0
  field :paid_billed_amount, type: Float, default: 0
end

# Invoice.where('services.entry_type': 'service').count

# db.finance_statistic_service.createIndex({"receipt_date": -1, "facility_id": 1 });
