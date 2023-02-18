class Comment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :comment_text, type: String
  field :created_by, type: BSON::ObjectId
  field :is_deleted, type: Boolean, default: false

  embedded_in :patient_summary_asset_upload, class_name: "::PatientSummaryAssetUpload"
end
