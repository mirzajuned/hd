class AppointmentType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :label, type: String
  field :duration, type: Integer
  field :background, type: String
  field :is_active, type: Boolean, default: true
  field :is_migrated, type: Boolean, default: true
  field :is_default, type: Boolean, default: false
  field :comment, type: String
  field :version, type: String, default: 'after_orange'
  field :matched_label, type: String
  field :specialty_ids, type: Array, default: []

  belongs_to :user, index: { background: true }, optional: true
  belongs_to :facility, index: { background: true }
  belongs_to :organisation, index: { background: true }
  belongs_to :organisation_appointment_type, index: { background: true }
end
