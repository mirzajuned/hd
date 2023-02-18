class PatientAssetUploadTag
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :doctor, type: BSON::ObjectId

  field :tag_name, type: String
  field :tag_name_lcase, type: String
  field :is_custom, type: String
  field :specialty_id, type: Integer

  belongs_to :patient_summary_asset_upload

  belongs_to :organisation, index: { background: true }
  belongs_to :facility, index: { background: true }
  belongs_to :user, index: { background: true }

  def self.normalize(s)
    s = s.upcase
    s = s.gsub("'", "")
    s = s.gsub("&", " AND ")
    s = s.gsub(/[^A-Z0-9 ]/, " ")
    s = s.gsub(/ THE /, "")
    s = s.squish
    s = " #{s}"
    s
  end
end
