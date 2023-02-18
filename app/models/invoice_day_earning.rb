class InvoiceDayEarning
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :total_earnings, type: Float
  field :date, type: Date

  belongs_to :user
  belongs_to :facility
end
