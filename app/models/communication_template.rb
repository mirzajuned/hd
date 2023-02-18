class CommunicationTemplate
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Enumerize

  field :template_title, type: String
  field :template_content, type: String
  field :organisation_id, type: BSON::ObjectId
  field :is_approved, type: Boolean, default: false
  field :communication_type, type: String
  field :module_names, type: Array, default: []
  validates_uniqueness_of :template_title
  field :display_name, type: String
  field :communication_number, type: String
  field :feature, type: Array
  field :is_disable, type: Boolean, default: false
  field :is_approved, type: Boolean
  field :type, type: Integer
  field :organisation_id, type: BSON::ObjectId
  enumerize :type, in: { whatsapp: 0, sms: 1 }, predicates: true
  has_many :communication_settings
  has_many :communication_events

  after_update :update_all_events

  def update_all_events
    communication_events.map { |p| p.update(message_format: template_content) }
  end
end
