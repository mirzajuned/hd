class PatientDiagnosis
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :opd_data, type: Array, default: []
  field :ipd_data, type: Array, default: []
  belongs_to :patient
  belongs_to :organisation
  field :is_migrated, type: Boolean, default: false

  def calculate_patient_age(form = false)
    if self.patient_dob_year.present?
      now = Date.current
      year = now.year - self.patient_dob_year.to_i - ((now.month > self.patient_dob_month.to_i || (now.month == self.patient_dob_month.to_i && now.day >= self.patient_dob_day.to_i)) ? 0 : 1)
      month = now.month - self.patient_dob_month.to_i
      day = now.day - self.patient_dob_day.to_i

      month = month + 12 if month < 0
      month = month - 1 if day < 0 && month != 0

      if month == 0
        age = year.to_s + ' yrs'
      elsif year <= 0
        age = month.to_s + ' mos '
      else
        age = year.to_s + ' yrs ' + month.to_s + ' mos'
      end
    end

    if form
      return year, month
    else
      return age
    end
  end
end
