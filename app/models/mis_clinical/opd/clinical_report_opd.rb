class MisClinical::Opd::ClinicalReportOpd
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing
  # document URL: https://docs.google.com/spreadsheets/d/1UDZR6tpK6f1r_fWFZocPA2uK04eIfQsS9JzPt0cBaTI/edit#gid=279741490

  field :patient_display_fields, type: Hash
  field :appointment_display_fields, type: Hash
  field :investigations, type: Array
  field :diagnoses, type: Array
  field :procedures, type: Array
  field :clinical_workflow, type: Array, default: []
  field :display_patient_role_wise_tat, type: Hash, default: {}
  field :patient_role_wise_tat_mins, type: Hash, default: {}
  field :patient_role_wise_tat_secs, type: Hash, default: {}
  field :filtering_fields, type: Hash
  field :search_fields, type: Hash
  field :custom_fields, type: Hash
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :appointment_id, type: BSON::ObjectId
  field :opd_clinical_workflow_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end


# db.mis_clinical_opd_clinical_report_opds.createIndex({"appointment_display_fields.appointment_start_time": -1, "facility_id": 1}, {name:"appointment_facility"})