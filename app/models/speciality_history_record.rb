# 1  Metrics/AbcSize
# 1  Metrics/CyclomaticComplexity
# 1  Metrics/MethodLength
# 1  Metrics/PerceivedComplexity
# --
# 4  Total
class SpecialityHistoryRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :r_duration, type: String
  field :l_duration, type: String
  field :r_duration_unit, type: String
  field :l_duration_unit, type: String
  field :comment, type: String
  field :option, type: String
  field :is_available, type: String
  field :_delete, type: Integer, default: 0
  field :record_created_date, type: DateTime
  field :record_updated_date, type: DateTime
  field :l_history_started, type: DateTime
  field :r_history_started, type: DateTime
  field :l_hidden_duration, type: String
  field :r_hidden_duration, type: String

  before_save :update_specialty_history_started

  field :history_started, type: DateTime

  embedded_in :opd_record, class_name: '::OpdRecord'
  embedded_in :patient, class_name: '::Patient'
  embedded_in :ipd_record, class_name: '::Inpatient::IpdRecord'

  def l_r_set_duration
    if l_history_started.present?
      l_time_difference = TimeDifference.between(Date.current, l_history_started)
      new_l_hidden_duration = l_time_difference.in_days.try(:round).to_s + '.days'

      if l_duration_unit.present? && l_time_difference.send("in_#{l_duration_unit.downcase}").to_i <= 40
        new_l_duration = l_time_difference.send("in_#{l_duration_unit}").to_i.round
        new_l_duration_unit = l_duration_unit
      elsif (1..40).cover?(l_time_difference.in_days)
        new_l_duration = l_time_difference.in_days.to_i.round
        new_l_duration_unit = 'days'
      elsif (1..40).cover?(l_time_difference.in_weeks)
        new_l_duration = l_time_difference.in_weeks.to_i.round
        new_l_duration_unit = 'weeks'
      elsif (1..40).cover?(l_time_difference.in_months)
        new_l_duration = l_time_difference.in_months.to_i.round
        new_l_duration_unit = 'months'
      elsif (1..40).cover?(l_time_difference.in_years)
        new_l_duration = l_time_difference.in_years.to_i.round
        new_l_duration_unit = 'years'
      end
    end

    if r_history_started.present?
      r_time_difference = TimeDifference.between(Date.current, r_history_started)
      new_r_hidden_duration = r_time_difference.in_days.try(:round).to_s + '.days'

      if r_duration_unit.present? && r_time_difference.send("in_#{r_duration_unit.downcase}").to_i <= 40
        new_r_duration = r_time_difference.send("in_#{r_duration_unit}").to_i.round
        new_r_duration_unit = r_duration_unit
      elsif (1..40).cover?(r_time_difference.in_days)
        new_r_duration = r_time_difference.in_days.to_i.round
        new_r_duration_unit = 'days'
      elsif (1..40).cover?(r_time_difference.in_weeks)
        new_r_duration = r_time_difference.in_weeks.to_i.round
        new_r_duration_unit = 'weeks'
      elsif (1..40).cover?(r_time_difference.in_months)
        new_r_duration = r_time_difference.in_months.to_i.round
        new_r_duration_unit = 'months'
      elsif (1..40).cover?(r_time_difference.in_years)
        new_r_duration = r_time_difference.in_years.to_i.round
        new_r_duration_unit = 'years'
      end
    end

    [new_l_hidden_duration, new_l_duration, new_l_duration_unit,
     new_r_hidden_duration, new_r_duration, new_r_duration_unit]
  end

  private

  def update_specialty_history_started
    if l_hidden_duration.present?
      self.l_history_started = Date.current - instance_eval(l_hidden_duration)
    elsif l_duration.present? && l_duration_unit.present?
      l_hidden_duration = "#{l_duration}.#{l_duration_unit.downcase}"
      self.l_hidden_duration = l_hidden_duration
      self.l_history_started = Date.current - instance_eval(l_hidden_duration)
    end

    if r_hidden_duration.present?
      self.r_history_started = Date.current - instance_eval(r_hidden_duration)
    elsif r_duration.present? && r_duration_unit.present?
      r_hidden_duration = "#{r_duration}.#{r_duration_unit.downcase}"
      self.r_hidden_duration = r_hidden_duration
      self.r_history_started = Date.current - instance_eval(r_hidden_duration)
    end
  end
end
