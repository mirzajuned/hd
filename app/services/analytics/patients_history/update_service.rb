module Analytics::PatientsHistory
  class UpdateService
    def self.call(params)
      old_history = params["old_systemic_history"]
      old_allergy = params["old_eye_drop_allergy"]

      new_history = params["new_systemic_history"]
      new_allergy = params["new_eye_drop_allergy"]

      old_dob_year = params["old_dob_year"]
      new_dob_year = params["new_dob_year"]
      org_id       = params["organisation_id"]
      old_gender   = params["old_gender"]
      new_gender   = params["new_gender"]

      analytics_history = Analytics::PatientHistory.find_by(organisation_id: org_id, dob_year: old_dob_year.try(:to_i), gender: old_gender)
      if analytics_history.present?
        # decrementing the old count for history
        old_history.to_s.split(",").each do |hist|
          field = hist.downcase.parameterize

          if analytics_history[field].present? && analytics_history[field] > 0
            analytics_history.inc("#{field}": -1)
            puts "decremented  #{field} by 1 history"
          end
        end

        # decrementing the old count for allergy
        old_allergy.to_s.split(",").each do |allergy|
          field = allergy.downcase.parameterize
          if analytics_history[field].present? && analytics_history[field] > 0
            analytics_history.inc("#{field}": -1)
            puts "decremented  #{field} by 1 allergy"
          end
        end
      end

      # incrementing in new patient
      analytics_history_new = Analytics::PatientHistory.find_by(organisation_id: org_id, dob_year: new_dob_year.try(:to_i), gender: new_gender)

      if analytics_history_new.present?
        # now incrementing the values
        new_history.to_s.split(",").each do |hist|
          field = hist.downcase.parameterize
          if analytics_history_new[field].present?
            analytics_history_new.inc("#{field}": 1)
            puts "#{field} --> history increased by 1"
          end
        end
        new_allergy.to_s.split(",").each do |allergy|
          field = allergy.downcase.parameterize
          if analytics_history_new[field].present?
            analytics_history_new.inc("#{field}": 1)
            puts "#{field} --> allergy increased by 1"
          end
        end
      else

        # create patient history analytics
        analytics_history_new = Analytics::PatientHistory.new
        if analytics_history_new.present?
          analytics_history_new.dob_year = new_dob_year.try(:to_i)
          analytics_history_new.organisation_id = org_id
          analytics_history_new.gender = new_gender
          analytics_history_new.save

          new_history.to_s.split(',').each do |hist|
            field = hist.downcase.parameterize
            if analytics_history_new[field].present?
              analytics_history_new.inc("#{field}": 1)
              puts "incremented #{field} history by 1 new"
            end
          end

          new_allergy.to_s.split(",").each do |allergy|
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
