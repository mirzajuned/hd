class PatientTracker
  include Mongoid::Document
  include Mongoid::Timestamps

  field :description, type: String
  field :tracker_type, type: String
  field :count, type: Integer
  field :unit, type: String # Day, Month, Week, Session
  # Date
  field :start_date, type: Date
  field :end_date, type: Date

  # Session
  field :session_dates, type: Array, default: []
  field :current_session, type: Integer

  # Soft Delete
  field :tracker_removed, type: Boolean, default: false

  belongs_to :patient
  belongs_to :user
  belongs_to :facility
  belongs_to :organisation
end
