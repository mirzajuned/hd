class AdverseEventsMailSetting
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :recipient_name, type: String
  field :recipient_mail, type: String
  field :stop_mail, type: Boolean, default: false
  field :send_mail, type: Boolean, default: true
  field :is_removed, type: Boolean, default: false

  # Validation
  validates :recipient_mail, presence: { message: 'Email cannot be blank.' },
                             format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/,
                                       message: 'Please enter a valid email' }

  validates_presence_of :recipient_name, message: 'Name cannot be blank.'

  after_save :update_domain_count

  def update_domain_count
    return unless recipient_mail_changed?

    new_domain = TrustedDomain.find_by(organisation_id: organisation_id, name: recipient_mail.to_s.split('@')[1],
                                       deleted: false)
    new_domain&.inc(use_count: 1)
  end
end
