class MisClinical::Ipd::PatientProcedureWise
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  # Patient
  field :patient_details, type: Hash

  field :procedure_id, type: String
  field :procedurestage, type: String
  field :procedureregion, type: String
  field :procedureside, type: String
  field :procedurestatus, type: String
  field :procedureapproach, type: String
  field :proceduretype, type: String
  field :procedurename, type: String
  field :procedurequalifier, type: String
  field :proceduresubqualifier, type: String
  field :counselling, type: Boolean, default: false
  field :billing, type: Boolean, default: false
  field :surgerydate, type: String
  field :procedure_type, type: String
  field :ot_checklist, type: Boolean, default: false
  field :ot_checklist_id, type: BSON::ObjectId
  field :has_complications, type: String, default: 'No'
  field :procedure_cnt, type: Integer

  field :is_advised, type: Boolean, default: true
  field :advised_by, type: String
  field :advised_by_id, type: BSON::ObjectId
  field :advised_at_facility, type: String
  field :advised_at_facility_id, type: BSON::ObjectId
  field :advised_datetime, type: DateTime

  # Agreed Details
  field :has_agreed, type: Boolean, default: false
  field :agreed_from, type: String
  field :agreed_by, type: String
  field :agreed_by_id, type: BSON::ObjectId
  field :agreed_at_facility, type: String
  field :agreed_at_facility_id, type: BSON::ObjectId
  field :agreed_datetime, type: DateTime

  # Declined Details
  field :has_declined, type: Boolean, default: false
  field :declined_from, type: String
  field :declined_by, type: String
  field :declined_by_id, type: BSON::ObjectId
  field :declined_at_facility, type: String
  field :declined_at_facility_id, type: BSON::ObjectId
  field :declined_datetime, type: DateTime

  # Payment Taken Details
  field :payment_taken, type: Boolean, default: false
  field :payment_taken_from, type: String
  field :payment_taken_by, type: String
  field :payment_taken_by_id, type: BSON::ObjectId
  field :payment_taken_at_facility, type: String
  field :payment_taken_at_facility_id, type: BSON::ObjectId
  field :payment_taken_datetime, type: DateTime

  # Converted Details
  field :is_converted, type: Boolean, default: false
  field :converted_from, type: String
  field :converted_by, type: String
  field :converted_by_id, type: BSON::ObjectId
  field :converted_at_facility, type: String
  field :converted_at_facility_id, type: BSON::ObjectId
  field :converted_datetime, type: DateTime

  field :in_admission, type: Boolean, default: false
  
  # Performed Details
  field :is_performed, type: Boolean, default: false
  field :performed_by, type: String
  field :performed_by_id, type: BSON::ObjectId
  field :performed_from, type: String
  field :performed_at_facility, type: String
  field :performed_at_facility_id, type: BSON::ObjectId
  # Comment this during migration
  field :performed_datetime, type: DateTime
  # Uncomment this during migration
  # field :performed_datetime_bkp, type: DateTime
  field :performed_comment, type: String
  field :users_comment, type: String

  field :performed_note_id, type: BSON::ObjectId

  # conversion in days
  field :conversion_time_days, type: String

  field :admission_id, type: BSON::ObjectId

  field :case_sheet_id, type: BSON::ObjectId

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId

  field :is_migrated, type: Boolean, default: false
end
