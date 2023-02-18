class Patientdata::AgeAtEncounter

  def self.call(patient_id, encounter_date)
    patient_obj = Patient.find_by(id: patient_id)
    if patient_obj.try(:is_approx_dob).equal?(true) # Handle is_approx_dob "true" scenario; means dob is NOT present
      begin
        patient_approx_date = Date.parse("#{patient_obj.dob_year}-#{patient_obj.dob_month}-#{patient_obj.dob_day}") # patient approx dob age
        age_at_encounter = (encounter_date.to_date - patient_approx_date.to_date).to_i / 365
        current_age = ((Date.current) - patient_approx_date).to_i / 365
        age_present = true # boolean field saving for rendering code in UI whether to display age or not.  
      rescue StandardError => e
        age_at_encounter = 1000 # keeping it as number allows us to do fast group / aggregration query
        current_age = 1000 # keeping it as number allows us to do fast group / aggregration query
        age_present = false
      end
    elsif patient_obj&.dob.present? && patient_obj.try(:is_approx_dob).equal?(false) # Handle is_approx_dob "false" scenario; means dob is present
      patient_dob_date = patient_obj.dob # patient dob age (exact)
      # age_at_encounter = (encounter_date - patient_dob_date).to_i / 365
      age_at_encounter = (encounter_date.to_date - patient_dob_date.to_date).to_i / 365
      current_age = ((Date.current) - patient_dob_date).to_i / 365
      age_present = true # boolean field saving for rendering code in UI whether to display age or not.
    else # Handle is_approx_dob "nil" scenario
      age_at_encounter = 1000 # keeping it as number allows us to do fast group / aggregration query
      current_age = 1000 # keeping it as number allows us to do fast group / aggregration query
      age_present = false # boolean field saving for rendering code in UI whether to display age or not.
    end
    [age_at_encounter, current_age, age_present]
  end
end
