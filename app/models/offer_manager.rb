class OfferManager
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  # field :organisation_id, type: BSON::ObjectId
  # field :facility_id, type: BSON::ObjectId
  belongs_to :organisation
  belongs_to :facility
  belongs_to :department

  field :department_ids, type: Array
  # field :department_id, type: String
  # field :department_name, type: String
  # field :department_display_name, type: String
  # field :department_display_order, type: Integer

  field :store_ids, type: Array
  field :store_id, type: String
  field :store_name, type: String

  field :offer_type, type: String # bill/item

  field :service_ids, type: Array
  field :service_id, type: BSON::ObjectId
  field :service_name, type: String

  field :name, type: String
  field :code_type, type: String, default: 'standard' #standard/dynamic
  field :standard_code, type: String
  field :dynamic_code_count, type: Float, default: 0.00

  field :start_date, type: Date
  field :start_datetime, type: Time
  field :end_date, type: Date
  field :end_datetime, type: Time
  field :offer_duration, type: Integer

  field :redeemed_count, type: Integer, default: 0

  field :discount, type: Integer #in percentage
  field :allow_with_other_offers, type: Boolean, default: true # Phase - II
  field :check_max_amount, type: Boolean, default: false
  field :max_amount, type: Float, default: 0.00 # Phase - II
  field :has_redeem_limit, type: Boolean, default: false # Phase - II
  field :redeem_limit, type: Integer # Phase - II

  field :is_active, type: Boolean, default: true
  field :is_migrated, type: Boolean, default: true

  embeds_many :dynamic_codes, class_name: '::OfferManager::DynamicCode' # Phase - II

  scope :type_asc, -> { order(department_display_name: :asc, start_datetime: :asc, end_datetime: :desc) }

  before_save :set_offer_duration

  def offer_code
    if self.code_type == 'standard'
      self.standard_code
    else
      self.dynamic_codes.first.dynamic_code
    end
  end

  def applicable_on
    if self.service_name.present?
      self.service_name.titleize
    else
      'NA'
    end
  end

  def checkboxes_checked(checked)
    checked&.split(',')
  end

  def set_offer_duration
    self.offer_duration = (self.end_date - self.start_date).to_i
  end
end

# db.offer_managers.createIndex({"created_at": 1, "organisation_id": 1, "services.price": 1, "is_migrated": 1 });