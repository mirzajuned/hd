class PatientRadioAssessmentReport
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :radiology_investigations, type: Array, default: []
  field :assessment_id, type: String
  field :investigation_name, type: String
  field :investigation_id, type: String
  field :investigation_side, type: String
  field :patient_id, type: String
  field :asset_path, type: String
  field :facility_id, type: String
  field :record_id, type: String
  field :upload_id, type: String

  mount_uploader :asset_path, InvestigationReportUploader
end
