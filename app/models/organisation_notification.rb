class OrganisationNotification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :body, type: String

  field :start_date, type: Date
  field :end_date, type: Date

  field :web_links, type: Array, default: []

  field :all_facilities, type: Boolean, default: false
  field :all_roles, type: Boolean, default: false

  field :active, type: Boolean, default: false
  field :deleted, type: Boolean, default: false

  field :role_ids, type: Array, default: []
  field :facility_ids, type: Array, default: []

  # Users who have acknowledged
  field :acknowledger_ids, type: Array, default: []

  # Users who marked read later
  field :rl_user_ids, type: Array, default: []

  belongs_to :user
  belongs_to :organisation

  validates_presence_of :title, :body, :start_date, :end_date
  validates_presence_of :role_ids, unless: :all_roles
  validates_presence_of :facility_ids, unless: :all_facilities

  validate :not_greater_start_date, if: -> { start_date && end_date }

  before_save :delete_web_links
  after_save :delete_notification_redis, if: -> { deleted_changed? || active_changed? }

  def not_greater_start_date
    errors.add(:start_date, 'should not be greater than End date') if start_date > end_date
  end

  def delete_web_links
    self.web_links = web_links.delete_if { |h| h[:link].blank? }
  end

  def delete_notification_redis
    organisation.user_ids.each do |user_id|
      Redis::Master.new.del("new_user_notification:#{user_id}")
      Redis::Master.new.del("old_user_notification:#{user_id}")
    end
  end

  def acknowledged?(user_id)
    acknowledger_ids.include?(user_id.to_s)
  end
end
