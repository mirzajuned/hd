class MisClinical::Opd::UserRoleWiseStats
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing
  # document URL: https://docs.google.com/spreadsheets/d/1UDZR6tpK6f1r_fWFZocPA2uK04eIfQsS9JzPt0cBaTI/edit#gid=279741490

  field :user_id, type: BSON::ObjectId
  field :user_name, type: String
  field :role_id, type: BSON::ObjectId
  field :role_label, type: String

  field :appoinment_date, type: Time
  field :patient_count, type: Integer
  field :min_time, type: Integer #secs
  field :max_time, type: Integer #secs
  field :avg_time, type: Integer #secs
  field :total_time, type: Integer #secs
  field :department_id, type: Integer, default: 440655000
  field :department_type, type: String, default: "OPD"

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :facility_timezone, type: String
  field :is_migrated, type: Boolean, default: true
end


# db.mis_clinical_opd_clinical_report_opds.createIndex({"appointment_display_fields.appointment_start_time": -1, "facility_id": 1}, {name:"appointment_facility"})