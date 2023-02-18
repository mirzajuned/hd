class PatientManagement
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :mode_of_communication, type: String
  field :reason_type, type: String
  # reason_type: Appointment,Birthday,Followup,LongOverdue
  field :date, type: Date
  field :time, type: Time
  belongs_to :patient
  belongs_to :user
  belongs_to :facility
end
