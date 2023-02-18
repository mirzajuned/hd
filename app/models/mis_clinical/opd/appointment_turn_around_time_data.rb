class MisClinical::Opd::AppointmentTurnAroundTimeData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  # Department - constant as it's OPD
  field :department_id, type: Integer, default: 440655000
  field :department, type: String, default: "OPD"

  # Patient Type Data
  field :patient_visit_type_id, type: BSON::ObjectId # Y
  field :patient_visit_type, type: String # Y

  # Appointment Data
  field :appointment_date, type: Date # Y
  field :appointment_id, type: BSON::ObjectId # Y
  field :appointment_type_id, type: BSON::ObjectId # N
  field :appointment_type, type: String # N

  # Role Id & Name
  field :role_id, type: BSON::ObjectId # Y
  field :role_name, type: String # Y
  field :role_label, type: String # Y

  # User Id & Name
  field :user_id, type: BSON::ObjectId # Y
  field :user_name, type: String # Y

  # User Id & Name
  field :display_tat, type: String # Y
  field :aggregated_tat_in_mins, type: Integer # Y
  field :aggregated_tat_in_secs, type: Integer
  # Below are commented for now.
  # field :engage_time, type: Hash
  # field :engage_time_display, type: String 

  # OpdClinicalWorkflow Id
  field :opd_clinical_workflow_id, type: BSON::ObjectId # Y

  field :facility_id, type: BSON::ObjectId # Y
  field :facility_name, type: String # Y

  field :organisation_id, type: BSON::ObjectId # Org Id # Y

  # ORIGINATING IDS AND FORM NAME
  field :primary_model_id, type: BSON::ObjectId # Y
  field :primary_model_name, type: String, default: "OpdClinicalWorkflow"

  field :filtering_fields, type: Hash
  field :search_fields, type: Hash
  field :custom_fields, type: Hash

  field :is_migrated, type: Boolean, default: true
end

#patient_visit
# "appointmenttype"=>"walkin", "appointment_type"=>"New"

# Patient Type
# Appointment Type
# Appointment Category
# Appointment Sub-Category
# Tag Group