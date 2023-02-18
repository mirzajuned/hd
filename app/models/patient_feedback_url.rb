class PatientFeedbackUrl
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  before_save :sanitize_url

  field :original_url, type: String
  field :host, type: String
  field :set_type, type: String
  field :short_url, type: String
  field :sanitized_url, type: String
  field :organisation_name, type: String
  field :patient_name, type: String
  field :appointment_id, type: BSON::ObjectId
  field :admission_id, type: BSON::ObjectId
  field :feedback_setting_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId
  field :expected_expiry_date, type: DateTime
  field :is_active, type: Boolean, default: true
  field :doctor_id, type: BSON::ObjectId

  validates_presence_of :short_url
  validates_uniqueness_of :short_url

  def generate_short_url
    url = ([*('a'..'z'), *(1..9)]).sample(6).join
    old_url = PatientFeedbackUrl.find_by(short_url: url)
    if old_url
      self.generate_short_url
    else
      self.short_url = url
    end
  end

  def sanitize_url
    if Rails.env == 'preproduction'
      domain_prefix = 'ppcrm.hgraph.in'
    elsif Rails.env == 'production'
      domain_prefix = 'crm.hgraph.in'
    else
      domain_prefix = 'localhost:3000'
    end

    self.original_url = "https://#{domain_prefix}/fd/" + "#{self.short_url}"
    self.sanitized_url = self.original_url.downcase.gsub(/(https?:\/\/)|(www\.)/, '')
  end
end
