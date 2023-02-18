class UserNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :category, type: String
  field :date_of_issue, type: Date # date at which medical is issued
  field :date_from, type: Date     # medical date starts from
  field :date_to, type: Date       # medical date ends at
  field :medical_subject, type: String
  field :medical_body, type: String

  scope :newest_certificate_first, -> { order('updated_at DESC') }
  field :patient_id, type: String
  field :user_id, type: String
  field :doctor, type: String
  field :type, type: String
end
