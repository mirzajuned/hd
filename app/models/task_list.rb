class TaskList
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :comment, type: String
  field :creation_date, type: Date
  field :completion_date, type: Date
  field :user_id, type: String
  field :organisation_id, type: String
  field :is_complete, type: Boolean, default: false
  field :position, type: Integer, default: 1
  field :is_active, type: Boolean, default: true

  default_scope -> { where(is_active: true) }
end
