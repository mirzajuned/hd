class Mis::Constants::DropdownValue
  def self.gender_type(params_query)
    mis_params = params_query[2]
    gender = {
      'All': '',
      'Male': 'Male',
      'Female': 'Female',
      'Transgender': 'Transgender'
    }
    [gender.to_a, mis_params[:gender_type]]
  end

  def self.role_id(params_query)
    mis_params = params_query[2]
    roles = Role.all.pluck(:label, :id)
    roles << ['Ophthalmology Technician', '2822900478']
    [['All', '']+roles, mis_params[:role_id]]
  end

  def self.appointmenttype(params_query)
    mis_params = params_query[2]
    appointmenttype = {
      'All': '',
      'Appointment': 'appointment',
      'Walkin': 'walkin'
    }
    [appointmenttype.to_a, mis_params[:appointmenttype]]
  end

  def self.dynamic_dropdown(filter, fac_and_org, mis_params)
    filter_name = filter.filter_name
    if filter_name.in?(['pharmacy_store', 'optical_store', 'facility'])
      dynamic_hash = {}
    else
      dynamic_hash = { 'All': '' }
    end
    if filter_name == 'pharmacy_store' || filter_name == 'optical_store'
      dynamic_hash = {}
      dynamic_values = Reports::Filter.find_by(
        filter_name: filter_name, facility_id: fac_and_org[0],
        organisation_id: fac_and_org[1], is_active: true
      )&.values
    else
      dynamic_values = Reports::Filter.find_by(
        filter_name: filter_name, organisation_id: fac_and_org[1], is_active: true
      )&.values
    end
    dynamic_hash.merge!(dynamic_values)
    default_value = if filter.filter_value_name == 'facility_id'
                      fac_and_org[0]
                    elsif filter.filter_value_name == 'pharmacy_store'
                      fac_and_org[2]
                    elsif filter.filter_value_name == 'optical_store'
                      fac_and_org[3]
                    else
                      ''
                    end
    [dynamic_hash.to_a, mis_params[filter.filter_value_name.to_sym] || default_value]
  end

  def self.consulting_doctor(params_query)
    mis_params = params_query[2]
    dynamic_hash = { 'All': '' }
    doctor = Facility.find_by(id: params_query[0]).users.where(role_ids: { '$in': [158965000, 158965000] })
                     .map { |val| [val.fullname, val.id.to_s] }.to_h
    dynamic_hash.merge!(doctor)
    [dynamic_hash.to_a, mis_params[:consulting_doctor]]
  end

  def self.performed_by(params_query)
    mis_params = params_query[2]
    dynamic_hash = { 'All': '' }
    doctor = User.where(facility_ids: params_query[0], role_ids: { '$in': [158965000, 158965000] })
                  .map { |val| [val.fullname, val.id.to_s] }.to_h
    dynamic_hash.merge!(doctor)
    [dynamic_hash.to_a, mis_params[:performed_by]]
  end

  def self.advised_by(params_query)
    mis_params = params_query[2]
    dynamic_hash = { 'All': '' }
    doctor = User.where(facility_ids: params_query[0], role_ids: { '$in': [158965000, 158965000] })
                  .map { |val| [val.fullname, val.id.to_s] }.to_h
    dynamic_hash.merge!(doctor)
    [dynamic_hash.to_a, mis_params[:advised_by]]
  end

  def self.appointment_type(params_query)
    mis_params = params_query[2]
    value = mis_params[:appointment_type].split(',') unless mis_params[:appointment_type].nil?
    appointment_type = AppointmentType.where(facility_id: params_query[0], is_active: true).to_a.pluck(:label)
    [appointment_type, value || '']
  end

  def self.bill_type(params_query)
    mis_params = params_query[2]
    invoice_type = {
      'All': '',
      'Cash': 'cash',
      'Credit': 'credit'
    }
    [invoice_type.to_a, mis_params[:bill_type]]
  end

  # Adverse Event Report Dropdowns Start
  def self.person_responsible(params_query)
    mis_params = params_query[2]
    dynamic_hash = { 'All': '' }
    person_responsible_users = User.where(facility_ids: mis_params[:facility_id])
                                   .map { |f| name_designation = f.fullname.titleize;
                                   name_designation += " (#{f.designation})" if f.designation.present?;
                                   ["#{name_designation}", f.id.to_s]}.to_h
    dynamic_hash.merge!(person_responsible_users)
    [dynamic_hash.to_a, mis_params[:person_responsible]]
  end

  def self.event_category(params_query)
    mis_params = params_query[2]
    event_category = {
      'All': '',
      'Critical': 'critical',
      'Major': 'major',
      'Minor': 'minor'
    }
    [event_category.to_a, mis_params[:event_category]]
  end

  def self.event_description(params_query)
    mis_params = params_query[2]
    event_description = {
      'All': '',
      'Patient Distress managed within Hospital premises': 'patient_distress',
      'Postop Inflammation not requiring IVAB/PPV': 'postop_inflammation',
      'Aqueous Meets Vitreous': 'aqueous_meets_vitreous',
      'Surgical complications/Repeat surgeries': 'surgical_complications_repeat_surgeries',
      'IOL related complication': 'wrong_iol_power',
      'OT CULTURE positive': 'culture_postivity_ot_electrical',
      'Complaint letter/Mail towards doctor or staff': 'customer_complaint_staff',
      'PBK following any surgery in our hospital within 1 year of initial surgery': 'pbk_surgery',
      'Rescheduling/cancelling surgery': 'rescheduling_cancelling_surgery',
      'Optical related': 'optical_related',
      'Biomedical/electrical/ project related issue leading to stoppage of OT': 'stoppage_of_OT',
      'Lab report of wrong patient or pharmacy dispensing wrong drugs': 'customer_complaint_department',
      'Consent form not taken': 'consent_not_taken',
      'Others': 'major_others',
      'Post Operative CME within 3 months': 'post_operative_CME_within_3_months',
      'Allergy to dilating drops': 'minor_drug_allergy',
      'Biomedical / project related instrument repair ( non OT)': 'bio_medical_instrument',
      'Iris prolapse /cortex wash /  re suturing wound  / iol re-dialling /AC reformation': 'simple_re_surgeries',
      'Conjunctivitis in COVID times': 'conjunctivitis_in_COVID_times',
      'Misdiagnosis, Mis management (e.g: uveitis Diagnosed as ACCO etc)': 'mis_diagnosis_management',
      'Others': 'minor_others',
      'Globe Perforation': 'globe_perforation',
      'Expulsive Hemorrhage': 'expulsive_hemorrhage',
      'Death inside hospital premises- during examination , pre intra or post op, GA related': 'death_inside_hospital_premises',
      'Major Distress Of Patient Which Requires Shifting To Emergency Services': 'shifting_to_emergency',
      'Death within 1 week of surgery': 'death_on_table_examination_during_surgeries',
      'Hospital staff or doctor testing COVID +': 'hospital_staff_or_doctor_testing_COVID_positive',
      'MLC Notifications To Hospital / Branch': 'mlc_notifications_hospital',
      'Customer Related Complaint To Public Forum': 'customer_complaint_public',
      'Wrong eye, wrong patient, wrong procedure': 'wrong_eye_patient_procedure',
      'Patient Harassment Issues': 'patient_harassment_issues',
      'Doctor or staff security issues': 'doctor_security_issues',
      'CODE PINK ( Child Abduction )': 'code_pink',
      'CODE RED ( Fire )': 'code_red',
      'Endopthalmitis obvious or suspected immediate or late': 'end_ophthlmitis',
      'Anaphylaxis / Major Drug Allergy': 'anaphylaxis_drug_allergy',
      'Others': 'critical_others'
    }
    [event_description.to_a, mis_params[:event_description]]
  end

  def self.sub_category(params_query)
    mis_params = params_query[2]
    sub_category = { 'All': '',
                     'GA or LA Related': 'ga_or_la_related',
                     'Vasovagal Attack': 'vasovagal_attack',
                     'Hypogylcemia': 'hypogylcemia',
                     'Wheezing or Urticaria after florescein': 'wheezing_or_urticaria_after_florescein',
                     'Fibrin Membrane': 'fibrin_membrane',
                     'Sterile Hypopyon': 'sterile_hypopyon',
                     'PC Rent': 'pc_rent',
                     'Zonular Dialysis': 'zonular_dialysis',
                     'PCR with Nucleus Drop': 'pcr_with_nucleus_drop',
                     'PCR with IOL Drop': 'pcr_with_iol_drop',
                     'Glued IOL': 'glued_iol',
                     'Cornea': 'cornea',
                     'Cataract': 'cataract',
                     'Refractive': 'refractive',
                     'Retina': 'retina',
                     'Squint - Revision Surgeries': 'squint_revision_surgeries',
                     'Glaucoma': 'glaucoma',
                     'Haptic Breakage': 'haptic_breakage',
                     'Wrong IOL Power leading to refractive surprise more than 2D': 'wrong_IOL_power_leading_to_refractive_surprise_more_than_2D',
                     'RBH': 'rbh',
                     'Patient Related': 'patient_related',
                     'Doctor Related': 'doctor_related',
                     'Others': 'others',
                     'Wrong Prescription': 'wrong_prescription',
                     'Vendor Related Misfit': 'vendor_related_misfit',
                     'Others': 'others' }
    [sub_category.to_a, mis_params[:sub_category]]
  end
  # Adverse Event Report Dropdowns End

  def self.department_id(params_query)
    mis_params = params_query[2]
    department_id_hash = { 'All': '' }
    ['485396012', '486546481', '50121007', '284748001'].each do |d_id|
      department = Department.find_by(id: d_id)
      department_id_hash.merge!(department.display_name => department.id.to_s)
    end
    [department_id_hash.to_a, mis_params[:department_id]]
  end

  def self.moh(params_query)
    mis_params = params_query[2]
    moh = {
      'All': '',
      'Cash': 'Cash',
      'Insured': 'Insured'
    }
    [moh.to_a, mis_params[:moh]]
  end

  def self.ipd_current_status(params_query)
    mis_params = params_query[2]
    status = {
      'All': '',
      'Scheduled': 'Scheduled',
      'Admitted': 'Admitted',
      'Discharged': 'Discharged',
      'Cancelled': 'Deleted'
    }
    [status.to_a, mis_params[:ipd_current_status]]
  end

  def self.admission_type(params_query)
    mis_params = params_query[2]
    type = {
      'All': '',
      'Planned': 'planned',
      'Emergency': 'emergency',
      'Same Day': 'same_day'
    }
    [type.to_a, mis_params[:admission_type]]
  end

  def self.date_wise(params_query)
    mis_params = params_query[2]
    status = {
      'Admission Date': 'Admitted',
      'Scheduled Date': 'Scheduled',
      'Discharged Date': 'Discharged'
    }
    [status.to_a, mis_params[:date_wise]]
  end

  def self.bill_status(params_query)
    mis_params = params_query[2]
    bill_status = {
      'All': '',
      'Cancel': 'is_cancelled',
      'Refunded': 'is_refunded'
    }
    [bill_status.to_a, mis_params[:bill_status]]
  end

  def self.procedure_state(params_query)
    mis_params = params_query[2]
    state = {
      'All': '',
      'Performed': 'performed',
      'Advised': 'advised'
    }
    [state.to_a, mis_params[:procedure_state]]
  end

  def self.investigation_type(params_query)
    mis_params = params_query[2]
    type = {
      'All': '',
      'Ophthal': 'Investigation::Ophthal',
      'Laboratory': 'Investigation::Laboratory',
      'Radiology': 'Investigation::Radiology'
    }
    [type.to_a, mis_params[:investigation_type]]
  end

  def self.investigation_state(params_query)
    mis_params = params_query[2]
    state = {
      'All': '',
      'Performed': 'performed',
      'Advised': 'advised',
      'Removed': 'removed'
    }
    [state.to_a, mis_params[:investigation_state]]
  end

  def self.performed_at(params_query)
    mis_params = params_query[2]
    state = {
      'All': '',
      'Outside': 'outside',
      'Inside': 'inside'
    }
    [state.to_a, mis_params[:performed_at]]
  end

  def self.doctor_type(params_query)
    mis_params = params_query[2]
    state = {
      'All': '',
      'Performed': 'performed',
      'Advised': 'advised'
    }
    [state.to_a, mis_params[:doctor_type]]
  end

  def self.procedure_date_wise(params_query)
    mis_params = params_query[2]
    state = {
      'Advised Date': 'advised',
      'Performed Date': 'performed'
    }
    [state.to_a, mis_params[:procedure_date_wise]]
  end

  def self.investigation_date_wise(params_query)
    mis_params = params_query[2]
    state = {
      'Advised Date': 'advised',
      'Performed Date': 'performed'
    }
    [state.to_a, mis_params[:investigation_date_wise]]
  end

  def self.pre_op_vision(params_query)
    mis_params = params_query[2]
    pre_op_vision = {
      'All': '',
      'VA': 'VA',
      'BCVA': 'BCVA'
    }
    [pre_op_vision.to_a, mis_params[:pre_op_vision]]
  end

  def self.post_op_vision(params_query)
    mis_params = params_query[2]
    post_op_vision = {
      'All': '',
      'VA': 'VA',
      'BCVA': 'BCVA'
    }
    [post_op_vision.to_a, mis_params[:post_op_vision]]
  end

  def self.va(params_query)
    mis_params = params_query[2]
    va = {
      'All': '',
      'PL-': 'PL-',
      'PL+': 'PL+',
      'FL': 'FL',
      'HM': 'HM',
      'CFCF': 'CFCF',
      'CF': 'CF',
      '1/60': '1/60',
      '2/60': '2/60',
      '3/60': '3/60',
      '4/60': '4/60',
      '5/60': '5/60',
      '6/60': '6/60',
      '6/36': '6/36',
      '6/24': '6/24',
      '6/18': '6/18',
      '6/12': '6/12',
      '6/9': '6/9',
      '6/7.5': '6/7.5',
      '6/6': '6/6',
      '6/5': '6/5'
    }
    [va.to_a, mis_params[:va]]
  end

  def self.logmar(params_query)
    mis_params = params_query[2]
    logmar = {
      'All': '',
      '-0.3': '-0.3',
      '-0.2': '-0.2',
      '-0.1': '-0.1',
      '0.0': '0.0',
      '0.1': '0.1',
      '0.2': '0.2',
      '0.3': '0.3',
      '0.4': '0.4',
      '0.5': '0.5',
      '0.6': '0.6',
      '0.7': '0.7',
      '0.8': '0.8',
      '0.9': '0.9',
      '1.0': '1.0',
      '1.1': '1.1',
      '1.2': '1.2',
      '1.3': '1.3',
      '1.4': '1.4'
    }
    [logmar.to_a, mis_params[:logmar]]
  end

  def self.conversion_status(params_query)
    mis_params = params_query[2]
    converted_status = {
      'All': '',
      'Advised': 'advised',
      'Converted': 'converted',
      'Not Converted': 'not_converted'
    }
    [converted_status.to_a, mis_params[:conversion_status]]
  end

  def self.referral_type(params_query)
    mis_params = params_query[2]
    referral_type = {
      'All': '',
      'Inter Facility': 'Inter Facility',
      'Intra Facility': 'Intra Facility',
      'Outside Organisation': 'Outside Organisation'
    }
    [referral_type.to_a, mis_params[:referral_type]]
  end

  def self.referral_source(params_query)
    mis_params = params_query[2]
    referral_source = {
      'All': '',
      'Self': 'Self',
      'Referring Doctor': 'Referring Doctor',
      'Staff Referral': 'Staff Referral',
      'Relative': 'Relative',
      'Campaign': 'Campaign',
      'Camp': 'Camp',
      'Institutional Referral': 'Institutional Referral',
      'Agent': 'Agent',
      'Online': 'Online',
      'Third Party': 'Third Party',
      'Consultant': 'Consultant'
    }
    [referral_source.to_a, mis_params[:referral_source]]
  end

  def self.discount_type(params_query)
    mis_params = params_query[2]
    discount_types = {
      'All': '',
      'Paid': 'paid',
      'Paid Discounted': 'paid_discounted',
      'Free Discounted': 'free_discounted',
      'Free': 'free'
    }
    [discount_types.to_a, mis_params[:discount_type]]
  end
  # EOF discount_type
end
