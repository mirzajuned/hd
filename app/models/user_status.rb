class UserStatus
  include Mongoid::Document
  include Mongoid::Timestamps

  field :start_time, type: DateTime
  field :end_time, type: DateTime
  field :state, type: String
  field :quota, type: String
  field :deleted, type: Boolean, default: false
  field :modified_by, type: String
  field :modified_by_id, type: String

  belongs_to :user
  belongs_to :organisation

  validates_presence_of :start_time, :state

  validates :state, inclusion: { in: ['active', 'inactive'] }
  validates :quota, inclusion: { in: [nil, 'paid', 'free'] }

  def span
    # TODO: Rethink
    # +1 for h/m/s
    TimeDifference.between(start_time.to_date, end_time&.to_date || Date.current).in_days
  end
end
