class CommunicationSetting
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Enumerize

  field :communication_number_id, type: BSON::ObjectId
  field :communication_template_ids, type: Array, default: []
  field :organisation_id, type: BSON::ObjectId
  field :facility_ids, type: Array, default: []
  field :communication_type, type: String
  field :is_disable, type: Boolean, default: false
  belongs_to :communication_number
end
