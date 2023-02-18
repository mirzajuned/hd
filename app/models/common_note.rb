class CommonNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :notes, type: String
  field :user_id, type: String

  embedded_in :patient_record_note
end
