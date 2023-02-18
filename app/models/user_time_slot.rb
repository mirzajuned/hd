class UserTimeSlot
  include Mongoid::Document
  include Mongoid::Timestamps

  field :calendar_duration, type: Integer

  validates_presence_of :calendar_duration

  validates :sessions, presence: { message: '- Atleast 1 session required.' }

  validates_numericality_of :calendar_duration, greater_than_or_equal_to: 0, less_than_or_equal_to: 120,
                                                message: 'must be between 0 & 120', if: :calendar_duration

  belongs_to :user
  belongs_to :organisation

  embeds_many :sessions, class_name: TimeSlot::Session
  accepts_nested_attributes_for :sessions, reject_if: :empty_session, allow_destroy: true

  embeds_many :exception_sessions, class_name: TimeSlot::ExceptionSession
  accepts_nested_attributes_for :exception_sessions, reject_if: :empty_session, allow_destroy: true

  private

  # Note: By using the attributes['id'] check we are ensuring that if other fields are empty with an existing record,
  # they are not restricted by the reject_if statement and can go ahead to be deleted (allow_destroy).
  def empty_session(attributes)
    attributes['id'].blank? && attributes['facility_id'].blank? && attributes['department_id'].blank? &&
      attributes['start_time'].blank? && attributes['end_time'].blank? &&
      attributes['slot_duration'].blank? && attributes['time_duration'].blank?
  end
end
