class Clinical::Ophthalmology::CheckLasikEligiblityJob < ActiveJob::Base
  queue_as :urgent

  def check_sum_sph_cyl(sph, cyl)
    if sph.blank? && cyl.blank?
      nil
    elsif sph.to_f > 0
      return false
    else
      sph.to_f.abs + cyl.to_f.abs <= 8
    end
  end

  def get_glass_prescription_result(opdrecord)
    check_glass_prescription_right_eye = check_sum_sph_cyl(opdrecord.r_glassesprescriptions_distant_sph, opdrecord.r_glassesprescriptions_distant_cyl)
    check_glass_prescription_left_eye = check_sum_sph_cyl(opdrecord.l_glassesprescriptions_distant_sph, opdrecord.l_glassesprescriptions_distant_cyl)
    result = check_glass_prescription_right_eye
    if result.blank?
      result = check_glass_prescription_left_eye unless check_glass_prescription_left_eye.nil?
    end
    result
  end

  def get_pgp_prescription_result(opdrecord, result)
    ['r', 'l'].each do |eyeside|
      ['', '2', '3'].each do |pgp_version|
        current_result = check_sum_sph_cyl(opdrecord.send("#{eyeside}_pgp_distant_sph#{pgp_version}"), opdrecord.send("#{eyeside}_pgp_distant_cyl#{pgp_version}"))
        result ||= current_result unless current_result.nil?
      end
    end
    result
  end

  def perform(mandatory, optional, others)
    opdrecord = OpdRecord.find_by(id: mandatory['opdrecord_id'])
    patient = Patient.find_by(id: mandatory['patient_id'])
    puts '============================== Lasik Eligiblity Job Running ====================================='  
    unless others["patient_lasik_status"].nil?
      patient.update(lasik_eligible: others["patient_lasik_status"])
    else 
      if patient.age.present? && opdrecord.specalityid == '309988001'
        result = get_glass_prescription_result(opdrecord)
        # If glass prescription values are nil, then PGPs will be considered.
        if result.nil?
          result = get_pgp_prescription_result(opdrecord, result)
        end
        result = false if (patient.age < 18 || patient.age > 40) && result == true
        patient.update(lasik_eligible: result)
      end
    end
  end
  # This job is created to check whether the person is lasik eligible or not. It runs after an opdrecord is created or updated.
end
