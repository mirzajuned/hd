class CommunicationDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :communication_type, type: String # email or sms
  field :communication_info, type: String # types are of followin g categories(followup sms,appointment sms,long overdue sms,birhday sms)
  field :communication_date, type: Date
  field :communication_month, type: Integer
  field :facility_id, type: String

  belongs_to :user
  belongs_to :organisation
  belongs_to :patient
end
