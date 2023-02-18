class LegacyAppointment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  belongs_to :legacy_patient
  field :reg_hosp_ids, type: Array

  # HEALTHGRAPH PATIENT IDS AND IMPORTANT CONFIGURATIONS
  field :new_patient_id
  field :legacy_appointment_id

  field :visit_type, type: String, default: "OPD"

  field :history, type: Array, default: []
  field :refraction, type: Array, default: []
  field :examination, type: Array, default: []
  field :diagnosis, type: Array, default: []
  field :investigation, type: Array, default: []
  field :surgery, type: Array, default: []
  field :advice, type: Array, default: []
  field :others, type: Array, default: []

  field :revision, type: Integer, default: 1

  # MIGRATED PATIENT DETAILS
  field :appointmentdate, type: DateTime
  field :patientnumber, type: String
  field :patientname, type: String
  field :notes, type: String
  field :doctor, type: String
  field :status, type: String
end
