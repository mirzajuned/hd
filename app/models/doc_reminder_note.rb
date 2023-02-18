class DocReminderNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :reminder_text, type: String
  field :reminder_tag, type: String # not using right now, might be needed in future

  field :patient_id, type: String
  field :doctor_id, type: String
  field :org_id, type: String # just in case if needed for migration
end
