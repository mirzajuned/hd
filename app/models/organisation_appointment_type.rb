class OrganisationAppointmentType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :label, type: String
  field :duration, type: Integer
  field :background, type: String
  field :is_active, type: Boolean, default: true
  field :is_default, type: Boolean, default: false
  field :default_set, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: true
  field :s_no, type: Integer
  field :specialty_ids, type: Array, default: []

  belongs_to :organisation, index: { background: true }
  has_many :appointment_types
end
