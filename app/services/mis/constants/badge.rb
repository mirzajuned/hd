class Mis::Constants::Badge
  def self.gender_type(badge)
    gender = {
      'Male': '<div class="badge badge-blue"> Male </div>',
      'Female': '<div class="badge badge-pink">Female </div>',
      'Transgender': '<div class="badge badge-purple">Transgender </div>'
    }
    gender[badge&.to_sym] || '--'
  end

  def self.event_category(badge)
    event_type = {
      'Critical': '<div class="badge badge-red"> Critical </div>',
      'Major': '<div class="badge badge-blue"> Major </div>',
      'Minor': '<div class="badge badge-purple"> Minor </div>'
    }
    event_type[badge&.to_sym] || '--'
  end

  def self.appointmenttype(badge)
    appointmenttype = {
      'appointment': '<div class="badge badge-success"> Appointment </div>',
      'walkin': '<div class="badge badge-warning"> Walkin </div>'
    }
    appointmenttype[badge&.to_sym] || '--'
  end

  def self.patient_visit(badge)
    patient_visit = {
      'New': '<div class="badge badge-success"> New </div>',
      'Followup': '<div class="badge badge-warning"> Followup </div>',
      'Post visit': '<div class="badge badge-red"> Post visit </div>'
    }
    patient_visit[badge&.to_sym] || "<div class='badge badge-purple'>#{badge&.titleize} </div>"
  end

  def self.appointment_type(badge)
    appointment_type = {
      'New': '<div class="badge badge-success"> New </div>',
      'Review': '<div class="badge badge-warning"> Review </div>',
      'Doctor Review': '<div class="badge badge-purple"> Doctor Review </div>',
      'PMT': '<div class="badge badge-yellow"> PMT </div>',
      'Investigation': '<div class="badge badge-blue"> Investigation </div>',
      'Surgery': '<div class="badge badge-red"> Surgery </div>',
      'Laser': '<div class="badge badge-pink"> Laser </div>',
      'Referral': '<div class="badge badge-success badge-grey"> Referral </div>',
      'Post OP': '<div class="badge badge-green"> Post OP </div>'
    }
    appointment_type[badge&.to_sym] || "<div class='badge badge-purple'>#{badge&.titleize} </div>"
  end

  def self.admission_type(badge)
    admission_type = {
      'planned': '<div class="badge badge-success"> Planned </div>',
      'emergency': '<div class="badge badge-red"> Emergency </div>',
      'same_day': '<div class="badge badge-pink"> Same Day </div>'
    }
    admission_type[badge&.to_sym] || '--'
  end

  def self.moh(badge)
    admission_type = {
      'Cash': '<div class="badge badge-green"> Cash </div>',
      'Insured': '<div class="badge badge-pink"> Insured </div>'
    }
    admission_type[badge&.to_sym] || '--'
  end

  def self.current_state(badge)
    current_state = {
      'Scheduled': '<div class="badge badge-pink"> Scheduled </div>',
      'Engaged': '<div class="badge badge-warning"> Engaged </div>',
      'Completed': '<div class="badge badge-success"> Completed </div>',
      'Waiting': '<div class="badge badge-yellow"> Waiting </div>',
      'Deleted': '<div class="badge badge-red"> Cancelled </div>',
      'Cancelled': '<div class="badge badge-red"> Cancelled </div>',
      'Admitted': '<div class="badge badge-warning"> Admitted </div>',
      'Discharged': '<div class="badge badge-success"> Discharged </div>',
      'Rescheduled': '<div class="badge badge-green"> Rescheduled </div>'
    }
    current_state[badge&.to_sym] || "<div class='badge badge-purple'>#{badge&.titleize} </div>"
  end

  def self.link_name(title)
    name = {
      'patient_detail': 'Visit Summary',
      'opd_statistics': 'Visit Statistics',
      'location_statistics': 'Patient By Region (city, state, etc.)',
      'referral_statistics': 'Referral Statistics',
      'inpatient_detail': 'Visit Summary',
      'ipd_date_wise': 'Admission Date Wise',
      'ipd_location_statistics': 'Patient By Region (city, state, etc.)',
      'ipd_statistics': 'Visit Statistics',
      'procedure_detail': 'Procedures Detail Report (advised or performed)',
      'procedure_performed': 'Procedures Performed By Date (with avg conversion time)',
      'advised_performed_procedure': 'Procedures Advised and Performed By Date',
      'daily_doctor_procedure': 'Procedures Advised and Performed By Doctor By Date',
      'daily_procedure_conversion': 'Procedures Advised and Performed By Procedure Name By Date',
      'advised_procedure_conversion': 'Procedures Advised vs Performed By Date (with avg conversion time)',
      'cumulative_doctor_procedure': 'Procedures Advised vs Performed By Doctor (for a period)',
      'cumulative_procedure_advised': 'Procedures Advised vs Performed By Procedure Name (for a period)',
      'patient_referred_to_summary': 'Patient Referred To Summary',
      'patient_referred_to_stats': 'Patient Referred To Statistics',
      'daily_doctor_investigation': 'Investigations Advised and Performed By Doctor By Date',
      'investigation_detail': 'Investigation Detail Report (advised or performed)',
      'investigation_performed': 'Investigations Performed By Date (with avg conversion time)',
      'advised_performed_investigation': 'Investigations Advised and Performed By Date',
      'advised_investigation_conversion': 'Investigations Advised vs Performed By Date (with avg conversion time)',
      'doctor_advised_investigation_conversion': 'Investigations Advised vs Performed By Doctor (for a period)',
      'daily_investigation_conversion': 'Investigations Advised and Performed By Investigation Name By Date',
      'cumulative_investigation_advised': 'Investigations Advised vs Performed By Investigation Name (for a period)',
      'diagnosis_stats': 'Diagnosis Date Wise Statistics'
    }
    name[title.to_sym] || title.titleize
  end

  def self.procedure_state(badge)
    admission_type = {
      'Performed': '<div class="badge badge-green"> Performed </div>',
      'Advised': '<div class="badge badge-pink"> Advised </div>'
    }
    admission_type[badge&.to_sym] || '--'
  end
end
