class PatientSummaryTimeline
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # ASSOCIATIONS
  belongs_to :organisation
  belongs_to :facility
  belongs_to :patient
  belongs_to :user, optional: true

  # FINDERS
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId

  # ACTUAL USER
  field :user_id, type: BSON::ObjectId
  field :user_name, type: String
  field :users, type: Array # Format [ {}, {}, {} ]

  # ACTUAL DEPARTMENTS
  field :department_id, type: BSON::ObjectId
  field :departments, type: Array # Format [ {}, {}, {} ]

  # DISPLAY FIELDS
  field :facility_name, type: String
  field :encounter_type, type: String
  field :encounter_date, type: Date
  field :encounter_date_time, type: DateTime

  # QUERY PARAMETERS
  field :query, type: Hash, default: {}
  field :primary_model, type: String

  # LINKS
  field :has_links, type: Boolean, default: false
  field :links, type: Hash, default: {}
  field :optionals, type: Hash, default: {}
  field :comments, type: Array, default: [] # []

  # EVENTS AND OTHER INFO
  field :is_active, type: Boolean, default: true # Check for Event/SubEvent
  field :event_id, type: Integer
  field :event_name, type: String
  field :event_type, type: String
  field :event_type_color, type: String
  field :event_date_time, type: DateTime
  field :sub_event_id, type: Integer
  field :sub_event_name, type: String
  field :department_name, type: String
  field :sub_department_name, type: String
  field :sub_speciality_name, type: String

  # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
  field :created_by, type: Array # []
  field :updated_by, type: Array # []

  # DELETED FLAG, FOR DISPLAY
  field :is_deleted, type: Boolean

  field :specialty_id, type: String
  field :is_migrated, type: Boolean, default: true

  # VALIDATIONS
  validates_presence_of :organisation_id
  validates_presence_of :facility_id
  validates_presence_of :patient_id
  validates_presence_of :facility_name
  # validates_presence_of :user_name
  validates_presence_of :encounter_type
  validates_presence_of :encounter_date
  validates_presence_of :encounter_date_time
  validates_presence_of :has_links
  validates_presence_of :links, if: :has_links?

  default_scope -> { where(is_deleted: false) }
end
