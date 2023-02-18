class OpdTemplateTag
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :doctor, type: BSON::ObjectId

  field :tag_name, type: String
  field :tag_name_lcase, type: String
  field :tag_type, type: Integer # Chief complaint (finding) SNOMED ID: 33962009, Patient given written advice (situation) SCTID: 413334001
  field :specialty_id, type: Integer
  field :is_custom, type: String

  belongs_to :organisation, index: { background: true }, optional: true
  belongs_to :facility, index: { background: true }, optional: true
  belongs_to :user, index: { background: true }, optional: true

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
