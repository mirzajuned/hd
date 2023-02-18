module Analytics::PatientsHistory
  class CreateService
    def self.call(params)
      dob_year             = params["dob_year"]
      org_id               = params["organisation_id"]
      new_systemic_history = params["new_systemic_history"]
      new_eye_drop_allergy = params["new_eye_drop_allergy"]
      new_gender           = params["gender"]
      analytics_history = Analytics::PatientHistory.find_by(organisation_id: org_id, dob_year: dob_year.try(:to_i), gender: new_gender)

      if analytics_history.present?

        new_systemic_history.to_s.split(",").each do |hist|
          field = hist.downcase.parameterize
          if analytics_history[field].present?
            analytics_history.inc("#{field}": 1)
            puts "incremented #{field}   history by 1 existing"
          end
        end

        new_eye_drop_allergy.to_s.split(",").each do |allergy|
          field = allergy.downcase.parameterize
          if analytics_history[field].present?
            analytics_history.inc("#{field}": 1)
            puts "incremented #{field}   allergy by 1 existing"

          end
        end

      else
        # create patient history analytics
        analytics_history_new = Analytics::PatientHistory.new
        if analytics_history_new.present?
          analytics_history_new.dob_year = dob_year.try(:to_i)
          analytics_history_new.organisation_id = org_id
          analytics_history_new.gender = new_gender
          analytics_history_new.save

          new_systemic_history.to_s.split(',').each do |hist|
            field = hist.downcase.parameterize
            if analytics_history_new[field].present?
              analytics_history_new.inc("#{field}": 1)
              puts "incremented #{field} history by 1 new"
            end
          end

          new_eye_drop_allergy.to_s.split(",").each do |allergy|
            field = allergy.downcase.parameterize
            if analytics_history_new[field].present?
              analytics_history_new.inc("#{field}": 1)
              puts "incremented #{field}  allergy by 1 new"
            end
          end

        end

      end
    end
  end
end
