class PatientRecordNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  embeds_many :common_note
  accepts_nested_attributes_for :common_note
end
