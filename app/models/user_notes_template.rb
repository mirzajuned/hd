class UserNotesTemplate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :template_details, type: String
  field :name, type: String
  field :specialty_id, type: String
  field :level, type: String # user, facility, organisation
  field :is_migrated, type: Boolean, default: true
  field :type, type: String
  field :is_deleted, type: Boolean, default: false

  belongs_to :user, optional: true
  belongs_to :facility, optional: true
  belongs_to :organisation, optional: true
end
