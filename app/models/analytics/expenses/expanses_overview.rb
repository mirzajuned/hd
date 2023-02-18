class Analytics::Expenses::ExpansesOverview
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :date, type: Date
  field :total_expanse, type: Integer
  field :total_paid, type: Float
  field :total_in_progress, type: Float
  field :total_unpaid, type: Float
  field :total_paid_count, type: Float
  field :total_in_progress_count, type: Float
  field :total_unpaid_count, type: Float
  field :facility_id, type: String
  field :organisation_id, type: String
end
