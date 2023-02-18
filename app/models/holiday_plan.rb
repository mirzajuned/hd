class HolidayPlan
  include Mongoid::Document
  include Mongoid::Timestamps

  field :start_date, type: Date
  field :end_date, type: Date
  field :start_time, type: Time
  field :end_time, type: Time
  field :plan, type: String
  field :reason, type: String

  belongs_to :user
  belongs_to :facility
  belongs_to :organisation

  before_save :default_values
  def default_values
    self.end_date ||= self.start_date
  end
end
