class OrganisationContract
  include Mongoid::Document
  include Mongoid::Timestamps

  field :customer_setup, type: String
  field :customer_type, type: String
  field :subscription_type, type: String
  field :pricing_type, type: String

  field :start_date, type: Date
  field :end_date, type: Date

  field :paid_quota, type: Integer, default: 0
  field :free_quota, type: Integer, default: 0
  field :variable_quota, type: Integer, default: 0

  field :base_rate_per_user, type: Float, default: 0.0
  field :discount_per_user, type: Float, default: 0.0

  field :created_by, type: String
  field :display_id, type: String

  field :active, type: Boolean, default: false
  field :deleted, type: Boolean, default: false

  belongs_to :organisation

  validates_presence_of :customer_setup, :customer_type, :subscription_type, :pricing_type,
                        :start_date, :end_date, :created_by, :display_id,
                        :paid_quota, :free_quota, :variable_quota, :base_rate_per_user, :discount_per_user
  validates_uniqueness_of :start_date, scope: :organisation_id, message: 'already exists'
  validates_uniqueness_of :display_id, scope: :organisation_id

  validate :start_after_today, if: :new_record?
  validate :end_after_start

  before_validation :update_counter, unless: :display_id
  before_validation :update_integer_fields
  after_create :activate

  def max_active_user
    paid_quota + free_quota + variable_quota
  end

  def total_rate_per_user
    base_rate_per_user - discount_per_user
  end

  def total_rate_per_user_per_day
    total_rate_per_user / 365
  end

  def activate
    OrganisationContractJobs::ActivateJob.set(wait_until: start_date.beginning_of_day)
                                         .perform_later(id.to_s, organisation_id.to_s)
  end

  def update_counter
    contract_counter = organisation.contract_counter || 1
    self.display_id = contract_counter < 10 ? "CON-0#{contract_counter}" : "CON-#{contract_counter}"

    organisation.set(contract_counter: contract_counter + 1)
  end

  def contract_code
    "#{customer_setup}-#{customer_type}"\
    "-#{subscription_type}-#{pricing_type}"
  end

  private

  def start_after_today
    return if start_date.nil? || Date.today <= start_date

    errors.add(:start_date, 'must be greater than Today')
  end

  def end_after_start
    return if end_date.nil? || start_date.nil? || start_date <= end_date

    errors.add(:end_date, 'must be greater than start date')
  end

  def update_integer_fields
    self.free_quota ||= 0
    self.variable_quota ||= 0
    self.discount_per_user ||= 0.0
  end
end
