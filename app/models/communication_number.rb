class CommunicationNumber
  include Mongoid::Document
  include Mongoid::Timestamps

  field :communication_number, type: String
  field :organisation_id, type: BSON::ObjectId
  field :is_approved, type: Boolean, default: true
  field :communication_type, type: String
  field :country_code, type: String
  field :country_flag, type: String
  validates_uniqueness_of :communication_number
  field :is_disable, type: Boolean, default: false
  has_many :communication_settings
  has_one :facility
  belongs_to :organisation
  validate :number_approved_checked

  def number_approved_checked
    phone_number = self.try(:country_code)+self.try(:communication_number)
    @response = CommunicationNotifications::WhatsappNotificationValidateService.call(phone_number, self.organisation.organisations_setting)
    if @response == "Notification sent successfully"
    else
      self.errors.add(:base, @response)
    end
  end
end
