class PatientInvestigationAsset
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :investigation_assets, type: String
  field :patient_investigation_id, type: String
  field :investigationside, type: String
  field :investigation_id, type: String
  field :investigation_image_path, type: String

  mount_uploader :investigation_image_path, PatientInvestigationUploader
end
