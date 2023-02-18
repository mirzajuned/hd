class SettingsAudit
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :facility_id, type: String
  field :organisation_id, type: String
  field :column_name, type: String
  field :level, type: String
  field :model_name, type: String
  field :controller_name, type: String
  field :action_name, type: String
  field :identifier, type: String
end
