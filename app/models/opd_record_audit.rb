class OpdRecordAudit
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :user_id, type: BSON::ObjectId
  field :action, type: String

  belongs_to :opd_record
end
