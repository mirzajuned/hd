class OrganisationAppointmentCategoryType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :label, type: String
  field :background, type: String
  field :is_active, type: Boolean, default: true
  field :user_id, type: String
  field :provided_by, type: String
  field :s_no, type: String
  field :specialty_ids, type: Array, default: []
  field :organisation_appointment_type_ids, type: Array, default: []
  field :default_set, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: true

  belongs_to :organisation, index: { background: true }
end
