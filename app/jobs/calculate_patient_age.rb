class CalculatePatientAge < ActiveJob::Base
  queue_as :delayed
  def perform
    Patient.all.each do |patient|
      if patient.dob.present?

        patientage = calculateage(patient.dob)
        patient.update(age: patientage)

      elsif patient.age.present? && patient.dob.blank?
        if patient.patientdobyear.present?
          patientage = Date.current.year - patient.patientdobyear.to_i
          patient.update(age: patientage)
        else
          patientdobyear = Date.current.year - patient.age
          patient.update(patientdobyear: patientdobyear)
        end
      end
    end

    def calculateage(dob)
      now = Time.current.utc.to_date
      now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
    end
  end
end
