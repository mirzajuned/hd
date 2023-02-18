class OpdRecordIdentifier
  include Mongoid::Document
  include Mongoid::Timestamps

  field :opd_record_org_id, type: String

  belongs_to :patient
  belongs_to :opd_record
  belongs_to :organisation
end
