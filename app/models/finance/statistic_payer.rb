class Finance::StatisticPayer
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :organisation_id, type: String
  field :facility_id, type: String
  field :facility_name, type: String
  field :receipt_date, type: Date
  field :payer_id, type: String
  field :payer_name, type: String
  field :payer_stats_fields, type: Hash

  field :is_migrated, type: Boolean, default: true

  field :filter_fields, type: Hash
  field :search_fields, type: Hash
end

# db.finance_statistic_payer.createIndex({ "receipt_date": -1, "facility_id": 1, "payer_id": 1 });
