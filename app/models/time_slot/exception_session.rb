class TimeSlot::ExceptionSession
  include Mongoid::Document
  include Mongoid::Timestamps

  field :days, type: Array, default: []

  field :start_time, type: String
  field :end_time, type: String

  field :start_date, type: Date
  field :end_date, type: Date

  field :slot_duration, type: Integer
  field :time_duration, type: Integer

  field :shared_id, type: String

  validates_presence_of :days, :department_id, :start_time, :end_time, :start_date, :end_date, :shared_id,
                        :slot_duration, :time_duration

  validate :correct_days
  validate :correct_start_date, if: -> { start_date.present? && start_date_changed? }
  validate :correct_end_date, if: -> { end_date.present? && end_date_changed? }
  validate :end_must_be_after_start_date, if: -> { start_date.present? && end_date.present? }
  validate :end_must_be_after_start_time, if: -> { start_time.present? && end_time.present? }
  validate :overlapping_dates, if: -> { start_date.present? && end_date.present? }
  validate :overlapping_times, if: -> { start_time.present? && end_time.present? }

  validates :start_time, format: { with: /((1[0-2]|0?[1-9]):([0-5][0-9]) ([AaPp][Mm]))/, message: 'is invalid' },
                         if: :start_time
  validates :end_time, format: { with: /((1[0-2]|0?[1-9]):([0-5][0-9]) ([AaPp][Mm]))/, message: 'is invalid' },
                       if: :end_time

  validates_numericality_of :slot_duration, greater_than_or_equal_to: 0, less_than_or_equal_to: 120,
                                            message: 'must be between 0 & 120', if: :slot_duration
  validates_numericality_of :time_duration, greater_than_or_equal_to: 0, less_than_or_equal_to: 120,
                                            message: 'must be between 0 & 120', if: :time_duration

  belongs_to :facility
  belongs_to :department

  embedded_in :user_time_slot

  scope :future, -> { where(:start_date.gt => Date.current) }
  scope :active, -> { where(:start_date.lte => Date.current, :end_date.gte => Date.current) }
  scope :completed, -> { where(:end_date.lt => Date.current) }
  scope :active_future, -> { where(:end_date.gte => Date.current) }

  def department_name
    department_id == '485396012' ? 'OPD' : 'IPD'
  end

  def max_bookings
    time_duration / slot_duration
  end

  def future
    start_date > Date.current
  end

  def active
    start_date <= Date.current && end_date >= Date.current
  end

  def completed
    end_date < Date.current
  end

  private

  def correct_days
    errors.add(:days, 'is not a valid day') if days.detect { |d| Date::DAYNAMES.exclude?(d) }
  end

  def correct_start_date
    errors.add(:start_date, 'must be after today') if start_date <= Date.current
  end

  def correct_end_date
    errors.add(:end_date, 'must be within 30 days') if end_date > (Date.today + 30.days)
  end

  def end_must_be_after_start_date
    errors.add(:end_date, 'must be after start date') if start_date > end_date
  end

  def end_must_be_after_start_time
    errors.add(:end_time, 'must be after start time') if Time.parse(start_time) >= Time.parse(end_time)
  end

  def overlapping_dates
    exception_sessions = user_time_slot.exception_sessions
                                       .where(:shared_id.ne => shared_id,
                                              '$or' => [
                                                { start_date: start_date..end_date },
                                                { end_date: start_date..end_date }
                                              ])
    errors.add(:start_date, 'or End date overlaps in another session') if exception_sessions.any?
  end

  def overlapping_times
    p_start_time = Time.parse(start_time)
    p_end_time = Time.parse(end_time)

    time_array.each do |t|
      # Condition checks whether time doesn't overlap either way.
      if (p_start_time.between?(t[0], t[1]) || p_end_time.between?(t[0], t[1])) ||
         (t[0].between?(p_start_time, p_end_time) || t[1].between?(p_start_time, p_end_time))
        return errors.add(:start_time, 'or End time overlaps in another session')
      end
    end
  end

  def time_array
    user_time_slot.exception_sessions
                  .where(:id.ne => id, shared_id: shared_id, :start_time.ne => '', :end_time.ne => '', :days.in => days)
                  .reject(&:_destroy) # To filter the sessions with _destroy: 1 flag
                  .map { |s| [Time.parse(s.start_time), Time.parse(s.end_time)] }
  end
end
