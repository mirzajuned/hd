class Reports::AnalyticsData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :organisation_id, type: String
  field :facility_id, type: String
  field :date, type: Date
  field :report_type, type: String # finance/clinical
  field :report_group, type: String
  field :display_fields, type: Hash
  field :is_active, type: Boolean, default: true
  field :is_migrated, type: Boolean, default: true
end

# db.reports_analytics_data.createIndex({"date": -1, "facility_id": 1, "organisation_id": 1 });