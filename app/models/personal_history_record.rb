# 1  Metrics/AbcSize
# 1  Metrics/CyclomaticComplexity
# 1  Metrics/MethodLength
# 1  Metrics/PerceivedComplexity
# --
# 4  Total
class PersonalHistoryRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :side, type: String
  field :duration, type: String
  field :duration_unit, type: String
  field :comment, type: String
  field :history_comment, type: String
  field :option, type: String
  field :record_created_date, type: DateTime
  field :record_updated_date, type: DateTime
  field :history_started, type: DateTime
  field :hidden_duration, type: String

  before_save :update_date
  embedded_in :opd_record, class_name: '::OpdRecord'
  embedded_in :patient, class_name: '::Patient'
  embedded_in :ipd_record, class_name: '::Inpatient::IpdRecord'

  def set_duration
    if history_started.present?
      time_difference = TimeDifference.between(Date.current, history_started)
      new_hidden_duration = "#{time_difference.in_days.to_i.round}.days"

      if duration_unit.present? && time_difference.send("in_#{duration_unit.downcase}").to_i <= 40
        new_duration = time_difference.send("in_#{duration_unit}").to_i.round
        new_duration_unit = duration_unit
      elsif (1..40).cover?(time_difference.in_days)
        new_duration = time_difference.in_days.to_i.round
        new_duration_unit = 'days'
      elsif (1..40).cover?(time_difference.in_weeks)
        new_duration = time_difference.in_weeks.to_i.round
        new_duration_unit = 'weeks'
      elsif (1..40).cover?(time_difference.in_months)
        new_duration = time_difference.in_months.to_i.round
        new_duration_unit = 'months'
      elsif (1..40).cover?(time_difference.in_years)
        new_duration = time_difference.in_years.to_i.round
        new_duration_unit = 'years'
      end
    end

    [new_hidden_duration, new_duration, new_duration_unit]
  end

  private

  def update_date
    if hidden_duration.present?
      self.history_started = Date.current - instance_eval(hidden_duration)
    elsif duration.present? && duration_unit.present?
      hidden_duration = "#{duration}.#{duration_unit.downcase}"
      self.hidden_duration = hidden_duration
      self.history_started = Date.current - instance_eval(hidden_duration)
    end
  end
end
