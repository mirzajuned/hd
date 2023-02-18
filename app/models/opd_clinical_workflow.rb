class OpdClinicalWorkflow
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  after_update :update_appointment_list_view

  field :state, type: String
  field :tpa_state, type: String
  field :tpa_admission_doctor, type: String
  field :tpa_admission_date, type: Date
  field :tpa_admission_id, type: BSON::ObjectId
  field :patient_id, type: String
  field :organisation_id, type: String
  field :facility_id, type: String
  field :user_id, type: String
  field :department_id, type: String
  field :appointmentdate, type: Date
  field :doctor_ids, type: Array, default: []
  field :optometrist_ids, type: Array, default: []
  field :ar_nct_ids, type: Array, default: []
  field :consultant_ids, type: Array, default: []
  field :_type, type: String
  field :end_time, type: Time
  field :start_time, type: Time
  field :transition_start, type: DateTime
  field :transition_end, type: DateTime
  field :dilation, type: Boolean, default: false
  field :calculate_away_time, type: Boolean, default: false
  field :patient_name, type: String
  field :patient_display_id, type: String
  field :appointment_type_label, type: String
  field :appointment_type_color, type: String
  field :appointmentstatus, type: String
  field :with_user, type: String
  field :with_user_role, type: String
  field :with_department, type: String
  field :appointment_category_label, type: String
  field :appointment_category_color, type: String

  field :away_time_general, type: Hash, default: {}
  field :away_time_seconds, type: Float, default: 0

  field :patient_type, type: String
  field :patient_type_color, type: String

  field :consultancy_type, type: String # h1.001 -> Free, h1.002 -> Paid
  field :consultancy_type_reason, type: String

  field :token_number, type: String
  field :in_department, type: Boolean, default: false

  # fields for referral
  field :intra_referral_id, type: BSON::ObjectId
  field :referral, type: Boolean, default: false
  field :referral_opd_record, type: BSON::ObjectId
  field :referral_type, type: String
  field :referring_doctor, type: String
  field :referral_note, type: String
  field :referee_doctor, type: String
  field :refer_to_facility_name, type: String
  field :refer_from_facility_name, type: String
  field :referral_created_on, type: Date # date on which referral is created
  field :referral_details, type: Hash

  field :appointment_type_comment, type: String

  # for multi-specialty
  field :specialty_id, type: String
  field :specialty_name, type: String
  field :department_id, type: String

  # QueueManagement
  field :in_station, type: Boolean, default: false
  field :station_id, type: BSON::ObjectId
  field :station_code, type: String
  field :station_name, type: String
  field :in_sub_station, type: Boolean, default: false
  field :sub_station_id, type: BSON::ObjectId
  field :sub_station_code, type: String
  field :area_id, type: BSON::ObjectId
  field :userless_station, type: Boolean, default: false
  field :is_qm_enabled, type: Boolean, default: false
  field :user_note, type: String
  field :transition_type, type: String
  field :state_type, type: String

  has_many :opd_clinical_workflow_state_transitions
  has_one :patient

  # index
  # index({ facility_id: 1, appointmentdate: 1 },{background: true})
  # db.opd_clinical_workflows.createIndex({ facility_id: 1, appointmentdate: 1 })
  # index({ organisation_id: 1, appointmentdate: 1 }
  # db.opd_clinical_workflows.createIndex({ organisation_id: 1, appointmentdate: 1 })
  # associations
  has_one :appointment, class_name: '::Appointment'
  has_one :facility, class_name: '::Facility'
  # state machine
  state_machine initial: :not_arrived do
    audit_trail initial: false, context: [:user_id, :department_id, :transition_start, :transition_end, :station_id,
                                          :station_code, :station_name, :sub_station_id, :sub_station_code, :area_id,
                                          :userless_station, :with_user, :user_note, :transition_type, :state_type]

    after_transition do |workflow|
      QueueManagementJobs::WorkflowJob.perform_later(workflow.id.to_s, workflow.facility_id.to_s)
    end


    # Queue Management Events
    event :check_out do
      transition [:receptionist, :nurse, :doctor, :optometrist, :counsellor, :optician, :pharmacist, :tpa_department,
                  :ophthal_investigation, :laboratory_investigation, :radiology_investigation, :not_arrived, :away,
                  :call, :check_out, :radiologist, :technician, :ophthalmology_technician, :cashier, :ar_nct, :floormanager] => :check_out
    end

    event :call_patient do
      transition check_out: :call
    end

    event :check_in_receptionist do
      transition [:check_out, :call] => :receptionist
    end

    event :check_in_nurse do
      transition [:check_out, :call] => :nurse
    end

    event :check_in_doctor do
      transition [:check_out, :call] => :doctor
    end

    event :check_in_optometrist do
      transition [:check_out, :call] => :optometrist
    end

    event :check_in_ar_nct do
      transition [:check_out, :call] => :ar_nct
    end

    event :check_in_counsellor do
      transition [:check_out, :call] => :counsellor
    end

    event :check_in_optical do
      transition [:check_out, :call] => :optical
    end

    event :check_in_optician do
      transition [:check_out, :call] => :optician
    end

    event :check_in_pharmacy do
      transition [:check_out, :call] => :pharmacy
    end

    event :check_in_pharmacist do
      transition [:check_out, :call] => :pharmacist
    end

    event :check_in_ophthalmology_technician do
      transition [:check_out, :call] => :ophthalmology_technician
    end

    event :check_in_ophthalmology_technician do
      transition [:check_out, :call] => :ophthalmology_technician
    end

    event :check_in_laboratory_investigation do
      transition [:check_out, :call] => :laboratory_investigation
    end

    event :check_in_technician do
      transition [:check_out, :call] => :technician
    end

    event :check_in_technician do
      transition [:check_out, :call] => :technician
    end

    event :check_in_radiology_investigation do
      transition [:check_out, :call] => :radiology_investigation
    end

    event :check_in_radiologist do
      transition [:check_out, :call] => :radiologist
    end

    event :check_in_tpa_department do
      transition [:check_out, :call] => :tpa_department
    end

    event :check_in_cashier do
      transition [:check_out, :call] => :cashier
    end

    event :check_in_floormanager do
      transition [:check_out, :call] => :floormanager
    end

    event :check_out_to_away do
      transition check_out: :away
    end

    event :call_to_away do
      transition call: :away
    end

    # Non-Queue Management Events

    # mark patient arrived
    event :arrived_to_receptionist do
      transition not_arrived: :receptionist
    end

    event :arrived_to_floormanager do
      transition not_arrived: :floormanager
    end

    event :arrived_to_cashier do
      transition not_arrived: :cashier
    end

    event :arrived_to_nurse do
      transition not_arrived: :nurse
    end

    event :arrived_to_doctor do
      transition not_arrived: :doctor
    end

    event :arrived_to_optometrist do
      transition not_arrived: :optometrist
    end

    event :arrived_to_ar_nct do
      transition not_arrived: :ar_nct
    end

    event :arrived_to_counsellor do
      transition not_arrived: :counsellor
    end

    event :arrived_to_waiting do
      transition not_arrived: :waiting
    end

    # events possible from receptionists
    event :receptionist_to_doctor do
      transition receptionist: :doctor
    end

    event :receptionist_to_nurse do
      transition receptionist: :nurse
    end

    event :receptionist_to_counsellor do
      transition receptionist: :counsellor
    end

    event :receptionist_to_investigator do
      transition receptionist: :investigator
    end

    event :receptionist_to_optometrist do
      transition receptionist: :optometrist
    end

    event :receptionist_to_ar_nct do
      transition receptionist: :ar_nct
    end

    event :receptionist_to_receptionist do
      transition receptionist: :receptionist
    end

    event :receptionist_to_floormanager do
      transition receptionist: :floormanager
    end

    event :receptionist_to_cashier do
      transition receptionist: :cashier
    end

    event :receptionist_to_optical do
      transition receptionist: :optical
    end

    event :receptionist_to_pharmacy do
      transition receptionist: :pharmacy
    end

    event :receptionist_to_ophthal_investigation do
      transition receptionist: :ophthal_investigation
    end

    event :receptionist_to_laboratory_investigation do
      transition receptionist: :laboratory_investigation
    end

    event :receptionist_to_radiology_investigation do
      transition receptionist: :radiology_investigation
    end

    event :receptionist_to_incomplete do
      transition receptionist: :incomplete
    end

    event :receptionist_to_technician do
      transition receptionist: :technician
    end

    event :receptionist_to_ophthalmology_technician do
      transition receptionist: :ophthalmology_technician
    end

    event :receptionist_to_radiologist do
      transition receptionist: :radiologist
    end

    event :receptionist_to_optician do
      transition receptionist: :optician
    end

    event :receptionist_to_pharmacist do
      transition receptionist: :pharmacist
    end

    # events possible from floormanager
    event :floormanager_to_doctor do
      transition floormanager: :doctor
    end

    event :floormanager_to_nurse do
      transition floormanager: :nurse
    end

    event :floormanager_to_counsellor do
      transition floormanager: :counsellor
    end

    event :floormanager_to_investigator do
      transition floormanager: :investigator
    end

    event :floormanager_to_optometrist do
      transition floormanager: :optometrist
    end

    event :floormanager_to_ar_nct do
      transition floormanager: :ar_nct
    end

    event :floormanager_to_receptionist do
      transition floormanager: :receptionist
    end

    event :floormanager_to_floormanager do
      transition floormanager: :floormanager
    end

    event :floormanager_to_cashier do
      transition floormanager: :cashier
    end

    event :floormanager_to_optical do
      transition floormanager: :optical
    end

    event :floormanager_to_pharmacy do
      transition floormanager: :pharmacy
    end

    event :floormanager_to_ophthal_investigation do
      transition floormanager: :ophthal_investigation
    end

    event :floormanager_to_laboratory_investigation do
      transition floormanager: :laboratory_investigation
    end

    event :floormanager_to_radiology_investigation do
      transition floormanager: :radiology_investigation
    end

    event :floormanager_to_incomplete do
      transition floormanager: :incomplete
    end

    event :floormanager_to_technician do
      transition floormanager: :technician
    end

    event :floormanager_to_ophthalmology_technician do
      transition floormanager: :ophthalmology_technician
    end

    event :floormanager_to_radiologist do
      transition floormanager: :radiologist
    end

    event :floormanager_to_optician do
      transition floormanager: :optician
    end

    event :floormanager_to_pharmacist do
      transition floormanager: :pharmacist
    end

    # events possible from cashier
    event :cashier_to_doctor do
      transition cashier: :doctor
    end

    event :cashier_to_nurse do
      transition cashier: :nurse
    end

    event :cashier_to_counsellor do
      transition cashier: :counsellor
    end

    event :cashier_to_investigator do
      transition cashier: :investigator
    end

    event :cashier_to_optometrist do
      transition cashier: :optometrist
    end

    event :cashier_to_ar_nct do
      transition cashier: :ar_nct
    end

    event :cashier_to_receptionist do
      transition cashier: :receptionist
    end

    event :cashier_to_floormanager do
      transition cashier: :floormanager
    end

    event :cashier_to_cashier do
      transition cashier: :cashier
    end

    event :cashier_to_optical do
      transition cashier: :optical
    end

    event :cashier_to_pharmacy do
      transition cashier: :pharmacy
    end

    event :cashier_to_ophthal_investigation do
      transition cashier: :ophthal_investigation
    end

    event :cashier_to_laboratory_investigation do
      transition cashier: :laboratory_investigation
    end

    event :cashier_to_radiology_investigation do
      transition cashier: :radiology_investigation
    end

    event :cashier_to_incomplete do
      transition cashier: :incomplete
    end

    event :cashier_to_technician do
      transition cashier: :technician
    end

    event :cashier_to_ophthalmology_technician do
      transition cashier: :ophthalmology_technician
    end

    event :cashier_to_radiologist do
      transition cashier: :radiologist
    end

    event :cashier_to_optician do
      transition cashier: :optician
    end

    event :cashier_to_pharmacist do
      transition cashier: :pharmacist
    end

    # events possible from nurses
    event :nurse_to_doctor do
      transition nurse: :doctor
    end

    event :nurse_to_counsellor do
      transition nurse: :counsellor
    end

    event :nurse_to_investigator do
      transition nurse: :investigator
    end

    event :nurse_to_optometrist do
      transition nurse: :optometrist
    end

    event :nurse_to_ar_nct do
      transition nurse: :ar_nct
    end

    event :nurse_to_nurse do
      transition nurse: :nurse
    end

    event :nurse_to_optical do
      transition nurse: :optical
    end

    event :nurse_to_pharmacy do
      transition nurse: :pharmacy
    end

    event :nurse_to_ophthal_investigation do
      transition nurse: :ophthal_investigation
    end

    event :nurse_to_laboratory_investigation do
      transition nurse: :laboratory_investigation
    end

    event :nurse_to_radiology_investigation do
      transition nurse: :radiology_investigation
    end

    event :nurse_to_incomplete do
      transition nurse: :incomplete
    end

    event :nurse_to_receptionist do
      transition nurse: :receptionist
    end

    event :nurse_to_floormanager do
      transition nurse: :floormanager
    end

    event :nurse_to_cashier do
      transition nurse: :cashier
    end

    event :nurse_to_technician do
      transition nurse: :technician
    end

    event :nurse_to_ophthalmology_technician do
      transition nurse: :ophthalmology_technician
    end

    event :nurse_to_radiologist do
      transition nurse: :radiologist
    end

    event :nurse_to_optician do
      transition nurse: :optician
    end

    event :nurse_to_pharmacist do
      transition nurse: :pharmacist
    end

    # events possible from doctor
    event :doctor_to_receptionist do
      transition doctor: :receptionist
    end

    event :doctor_to_floormanager do
      transition doctor: :floormanager
    end

    event :doctor_to_cashier do
      transition doctor: :cashier
    end

    event :doctor_to_nurse do
      transition doctor: :nurse
    end

    event :doctor_to_optometrist do
      transition doctor: :optometrist
    end

    event :doctor_to_ar_nct do
      transition doctor: :ar_nct
    end

    event :doctor_to_investigator do
      transition doctor: :investigator
    end

    event :doctor_to_counsellor do
      transition doctor: :counsellor
    end

    event :doctor_to_doctor do
      transition doctor: :doctor
    end

    event :doctor_to_optical do
      transition doctor: :optical
    end

    event :doctor_to_pharmacy do
      transition doctor: :pharmacy
    end

    event :doctor_to_ophthal_investigation do
      transition doctor: :ophthal_investigation
    end

    event :doctor_to_laboratory_investigation do
      transition doctor: :laboratory_investigation
    end

    event :doctor_to_radiology_investigation do
      transition doctor: :radiology_investigation
    end

    event :doctor_to_incomplete do
      transition doctor: :incomplete
    end

    event :doctor_to_technician do
      transition doctor: :technician
    end

    event :doctor_to_ophthalmology_technician do
      transition doctor: :ophthalmology_technician
    end

    event :doctor_to_radiologist do
      transition doctor: :radiologist
    end

    event :doctor_to_optician do
      transition doctor: :optician
    end

    event :doctor_to_pharmacist do
      transition doctor: :pharmacist
    end

    # events possible from investigator
    event :investigator_to_receptionist do
      transition investigator: :receptionist
    end

    event :investigator_to_floormanager do
      transition investigator: :floormanager
    end

    event :investigator_to_cashier do
      transition investigator: :cashier
    end

    event :investigator_to_nurse do
      transition investigator: :nurse
    end

    event :investigator_to_incomplete do
      transition investigator: :incomplete
    end

    # events possible from optometrist
    event :optometrist_to_receptionist do
      transition optometrist: :receptionist
    end

    event :optometrist_to_floormanager do
      transition optometrist: :floormanager
    end

    event :optometrist_to_cashier do
      transition optometrist: :cashier
    end

    event :optometrist_to_nurse do
      transition optometrist: :nurse
    end

    event :optometrist_to_doctor do
      transition optometrist: :doctor
    end

    event :optometrist_to_optometrist do
      transition optometrist: :optometrist
    end

    event :optometrist_to_ar_nct do
      transition optometrist: :ar_nct
    end

    event :optometrist_to_counsellor do
      transition optometrist: :counsellor
    end

    event :optometrist_to_optical do
      transition optometrist: :optical
    end

    event :optometrist_to_pharmacy do
      transition optometrist: :pharmacy
    end

    event :optometrist_to_ophthal_investigation do
      transition optometrist: :ophthal_investigation
    end

    event :optometrist_to_laboratory_investigation do
      transition optometrist: :laboratory_investigation
    end

    event :optometrist_to_radiology_investigation do
      transition optometrist: :radiology_investigation
    end

    event :optometrist_to_incomplete do
      transition optometrist: :incomplete
    end

    event :optometrist_to_technician do
      transition optometrist: :technician
    end

    event :optometrist_to_ophthalmology_technician do
      transition optometrist: :ophthalmology_technician
    end

    event :optometrist_to_radiologist do
      transition optometrist: :radiologist
    end

    event :optometrist_to_optician do
      transition optometrist: :optician
    end

    event :optometrist_to_pharmacist do
      transition optometrist: :pharmacist
    end

    # events possible from ar_nct
    event :ar_nct_to_receptionist do
      transition ar_nct: :receptionist
    end

    event :ar_nct_to_floormanager do
      transition ar_nct: :floormanager
    end

    event :ar_nct_to_cashier do
      transition ar_nct: :cashier
    end

    event :ar_nct_to_nurse do
      transition ar_nct: :nurse
    end

    event :ar_nct_to_doctor do
      transition ar_nct: :doctor
    end

    event :ar_nct_to_optometrist do
      transition ar_nct: :optometrist
    end

    event :ar_nct_to_ar_nct do
      transition ar_nct: :ar_nct
    end

    event :ar_nct_to_counsellor do
      transition ar_nct: :counsellor
    end

    event :ar_nct_to_optical do
      transition ar_nct: :optical
    end

    event :ar_nct_to_pharmacy do
      transition ar_nct: :pharmacy
    end

    event :ar_nct_to_ophthal_investigation do
      transition ar_nct: :ophthal_investigation
    end

    event :ar_nct_to_laboratory_investigation do
      transition ar_nct: :laboratory_investigation
    end

    event :ar_nct_to_radiology_investigation do
      transition ar_nct: :radiology_investigation
    end

    event :ar_nct_to_incomplete do
      transition ar_nct: :incomplete
    end

    event :ar_nct_to_technician do
      transition ar_nct: :technician
    end

    event :ar_nct_to_ophthalmology_technician do
      transition ar_nct: :ophthalmology_technician
    end

    event :ar_nct_to_radiologist do
      transition ar_nct: :radiologist
    end

    event :ar_nct_to_optician do
      transition ar_nct: :optician
    end

    event :ar_nct_to_pharmacist do
      transition ar_nct: :pharmacist
    end

    # complete or end patient
    event :complete do
      transition [:optometrist, :ar_nct, :doctor, :receptionist, :floormanager, :cashier, :nurse, :counsellor, :optical,
                  :pharmacy, :waiting, :engaged, :ophthal_investigation, :laboratory_investigation,
                  :radiology_investigation, :check_out, :pharmacist, :optician, :radiologist, :technician,
                  :ophthalmology_technician, :pharmacist, :optician, :technician, :ophthalmology_technician] => :complete
    end

    # undo complete
    event :complete_to_receptionist do
      transition complete: :receptionist
    end

    event :complete_to_floormanager do
      transition complete: :floormanager
    end

    event :complete_to_cashier do
      transition complete: :cashier
    end

    event :complete_to_nurse do
      transition complete: :nurse
    end

    event :complete_to_doctor do
      transition complete: :doctor
    end

    event :complete_to_optometrist do
      transition complete: :optometrist
    end

    event :complete_to_ar_nct do
      transition complete: :ar_nct
    end

    event :complete_to_optical do
      transition complete: :optical
    end

    event :complete_to_pharmacy do
      transition complete: :pharmacy
    end

    event :complete_to_ophthal_investigation do
      transition complete: :ophthal_investigation
    end

    event :complete_to_laboratory_investigation do
      transition complete: :laboratory_investigation
    end

    event :complete_to_radiology_investigation do
      transition complete: :radiology_investigation
    end

    event :complete_to_technician do
      transition complete: :technician
    end

    event :complete_to_ophthalmology_technician do
      transition complete: :ophthalmology_technician
    end

    event :complete_to_radiologist do
      transition complete: :radiologist
    end

    event :complete_to_optician do
      transition complete: :optician
    end

    event :complete_to_pharmacist do
      transition complete: :pharmacist
    end

    # events possible from counsellor
    event :counsellor_to_receptionist do
      transition counsellor: :receptionist
    end

    event :counsellor_to_floormanager do
      transition counsellor: :floormanager
    end

    event :counsellor_to_cashier do
      transition counsellor: :cashier
    end

    event :counsellor_to_nurse do
      transition counsellor: :nurse
    end

    event :counsellor_to_doctor do
      transition counsellor: :doctor
    end

    event :counsellor_to_optometrist do
      transition counsellor: :optometrist
    end

    event :counsellor_to_ar_nct do
      transition counsellor: :ar_nct
    end

    event :counsellor_to_counsellor do
      transition counsellor: :counsellor
    end

    event :counsellor_to_optical do
      transition counsellor: :optical
    end

    event :counsellor_to_pharmacy do
      transition counsellor: :pharmacy
    end

    event :counsellor_to_ophthal_investigation do
      transition counsellor: :ophthal_investigation
    end

    event :counsellor_to_laboratory_investigation do
      transition counsellor: :laboratory_investigation
    end

    event :counsellor_to_radiology_investigation do
      transition counsellor: :radiology_investigation
    end

    event :counsellor_to_incomplete do
      transition counsellor: :incomplete
    end

    event :counsellor_to_tpa_department do
      transition counsellor: :tpa_department
    end

    event :counsellor_to_tpa do
      transition counsellor: :tpa
    end

    event :counsellor_to_technician do
      transition counsellor: :technician
    end

    event :counsellor_to_ophthalmology_technician do
      transition counsellor: :ophthalmology_technician
    end

    event :counsellor_to_radiologist do
      transition counsellor: :radiologist
    end

    event :counsellor_to_optician do
      transition counsellor: :optician
    end

    event :counsellor_to_pharmacist do
      transition counsellor: :pharmacist
    end

    # events possible from tpa
    event :tpa_to_receptionist do
      transition tpa: :receptionist
    end

    event :tpa_to_floormanager do
      transition tpa: :floormanager
    end

    event :tpa_to_cashier do
      transition tpa: :cashier
    end

    event :tpa_to_nurse do
      transition tpa: :nurse
    end

    event :tpa_to_doctor do
      transition tpa: :doctor
    end

    event :tpa_to_optometrist do
      transition tpa: :optometrist
    end

    event :tpa_to_ar_nct do
      transition tpa: :ar_nct
    end

    event :tpa_to_optical do
      transition tpa: :optical
    end

    event :tpa_to_pharmacy do
      transition tpa: :pharmacy
    end

    event :tpa_to_ophthal_investigation do
      transition tpa: :ophthal_investigation
    end

    event :tpa_to_laboratory_investigation do
      transition tpa: :laboratory_investigation
    end

    event :tpa_to_radiology_investigation do
      transition tpa: :radiology_investigation
    end

    event :tpa_to_counsellor do
      transition tpa: :counsellor
    end

    event :tpa_to_technician do
      transition tpa: :technician
    end

    event :tpa_to_ophthalmology_technician do
      transition tpa: :ophthalmology_technician
    end

    event :tpa_to_radiologist do
      transition tpa: :radiologist
    end

    event :tpa_to_optician do
      transition tpa: :optician
    end

    event :tpa_to_pharmacist do
      transition tpa: :pharmacist
    end

    # events possible from tpa department
    event :tpa_department_to_receptionist do
      transition tpa_department: :receptionist
    end

    event :tpa_department_to_floormanager do
      transition tpa_department: :floormanager
    end

    event :tpa_department_to_cashier do
      transition tpa_department: :cashier
    end

    event :tpa_department_to_nurse do
      transition tpa_department: :nurse
    end

    event :tpa_department_to_doctor do
      transition tpa_department: :doctor
    end

    event :tpa_department_to_optometrist do
      transition tpa_department: :optometrist
    end

    event :tpa_department_to_ar_nct do
      transition tpa_department: :ar_nct
    end

    event :tpa_department_to_optical do
      transition tpa_department: :optical
    end

    event :tpa_department_to_pharmacy do
      transition tpa_department: :pharmacy
    end

    event :tpa_department_to_ophthal_investigation do
      transition tpa_department: :ophthal_investigation
    end

    event :tpa_department_to_laboratory_investigation do
      transition tpa_department: :laboratory_investigation
    end

    event :tpa_department_to_radiology_investigation do
      transition tpa_department: :radiology_investigation
    end

    event :tpa_department_to_counsellor do
      transition tpa_department: :counsellor
    end

    event :tpa_department_to_technician do
      transition tpa_department: :technician
    end

    event :tpa_department_to_ophthalmology_technician do
      transition tpa_department: :ophthalmology_technician
    end

    event :tpa_department_to_radiologist do
      transition tpa_department: :radiologist
    end

    event :tpa_department_to_optician do
      transition tpa_department: :optician
    end

    event :tpa_department_to_pharmacist do
      transition tpa_department: :pharmacist
    end

    # events possible from optical
    event :optician_to_receptionist do
      transition optician: :receptionist
    end

    event :optician_to_floormanager do
      transition optician: :floormanager
    end

    event :optician_to_cashier do
      transition optician: :cashier
    end

    event :optician_to_nurse do
      transition optician: :nurse
    end

    event :optician_to_doctor do
      transition optician: :doctor
    end

    event :optician_to_optometrist do
      transition optician: :optometrist
    end

    event :optician_to_ar_nct do
      transition optician: :ar_nct
    end

    event :optician_to_counsellor do
      transition optician: :counsellor
    end

    event :optician_to_pharmacy do
      transition optician: :pharmacy
    end

    event :optician_to_incomplete do
      transition optician: :incomplete
    end

    event :optician_to_ophthal_investigation do
      transition optician: :ophthal_investigation
    end

    event :optician_to_laboratory_investigation do
      transition optician: :laboratory_investigation
    end

    event :optician_to_radiology_investigation do
      transition optician: :radiology_investigation
    end

    event :optical_to_incomplete do
      transition optical: :incomplete
    end

    event :optician_to_technician do
      transition optician: :technician
    end

    event :optician_to_ophthalmology_technician do
      transition optician: :ophthalmology_technician
    end

    event :optician_to_radiologist do
      transition optician: :radiologist
    end

    event :optician_to_optician do
      transition optician: :optician
    end

    event :optician_to_pharmacist do
      transition optician: :pharmacist
    end

    # events possible from pharmacy
    event :pharmacist_to_receptionist do
      transition pharmacist: :receptionist
    end

    event :pharmacist_to_floormanager do
      transition pharmacist: :floormanager
    end

    event :pharmacist_to_cashier do
      transition pharmacist: :cashier
    end

    event :pharmacist_to_nurse do
      transition pharmacist: :nurse
    end

    event :pharmacist_to_doctor do
      transition pharmacist: :doctor
    end

    event :pharmacist_to_optometrist do
      transition pharmacist: :optometrist
    end

    event :pharmacist_to_ar_nct do
      transition pharmacist: :ar_nct
    end

    event :pharmacist_to_counsellor do
      transition pharmacist: :counsellor
    end

    event :pharmacist_to_optical do
      transition pharmacist: :optical
    end

    event :pharmacist_to_ophthal_investigation do
      transition pharmacist: :ophthal_investigation
    end

    event :pharmacist_to_laboratory_investigation do
      transition pharmacist: :laboratory_investigation
    end

    event :pharmacist_to_radiology_investigation do
      transition pharmacist: :radiology_investigation
    end

    event :pharmacist_to_incomplete do
      transition pharmacist: :incomplete
    end

    event :pharmacist_to_technician do
      transition pharmacist: :technician
    end

    event :pharmacist_to_ophthalmology_technician do
      transition pharmacist: :ophthalmology_technician
    end

    event :pharmacist_to_radiologist do
      transition pharmacist: :radiologist
    end

    event :pharmacist_to_optician do
      transition pharmacist: :optician
    end

    event :pharmacist_to_pharmacist do
      transition pharmacist: :pharmacist
    end

    # events possible from ophthal_investigation
    event :ophthalmology_technician_to_receptionist do
      transition ophthalmology_technician: :receptionist
    end

    event :ophthalmology_technician_to_floormanager do
      transition ophthalmology_technician: :floormanager
    end

    event :ophthalmology_technician_to_cashier do
      transition ophthalmology_technician: :cashier
    end

    event :ophthalmology_technician_to_nurse do
      transition ophthalmology_technician: :nurse
    end

    event :ophthalmology_technician_to_doctor do
      transition ophthalmology_technician: :doctor
    end

    event :ophthalmology_technician_to_optometrist do
      transition ophthalmology_technician: :optometrist
    end

    event :ophthalmology_technician_to_ar_nct do
      transition ophthalmology_technician: :ar_nct
    end

    event :ophthalmology_technician_to_counsellor do
      transition ophthalmology_technician: :counsellor
    end

    event :ophthalmology_technician_to_optical do
      transition ophthalmology_technician: :optical
    end

    event :ophthalmology_technician_to_pharmacy do
      transition ophthalmology_technician: :pharmacy
    end

    event :ophthalmology_technician_to_laboratory_investigation do
      transition ophthalmology_technician: :laboratory_investigation
    end

    event :ophthalmology_technician_to_radiology_investigation do
      transition ophthalmology_technician: :radiology_investigation
    end

    event :ophthalmology_technician_to_incomplete do
      transition ophthalmology_technician: :incomplete
    end

    event :ophthalmology_technician_to_technician do
      transition ophthalmology_technician: :technician
    end

    event :ophthalmology_technician_to_ophthalmology_technician do
      transition ophthalmology_technician: :ophthalmology_technician
    end

    event :ophthalmology_technician_to_radiologist do
      transition ophthalmology_technician: :radiologist
    end

    event :ophthalmology_technician_to_optician do
      transition ophthalmology_technician: :optician
    end

    event :ophthalmology_technician_to_ophthalmology_technician do
      transition pharmacist: :pharmacist
    end

    # events possible from laboratory_investigation
    event :technician_to_receptionist do
      transition technician: :receptionist
    end

    event :technician_to_floormanager do
      transition technician: :floormanager
    end

    event :technician_to_cashier do
      transition technician: :cashier
    end

    event :technician_to_nurse do
      transition technician: :nurse
    end

    event :technician_to_doctor do
      transition technician: :doctor
    end

    event :technician_to_optometrist do
      transition technician: :optometrist
    end

    event :technician_to_ar_nct do
      transition technician: :ar_nct
    end

    event :technician_to_counsellor do
      transition technician: :counsellor
    end

    event :technician_to_optical do
      transition technician: :optician
    end

    event :technician_to_pharmacy do
      transition technician: :pharmacist
    end

    event :technician_to_ophthal_investigation do
      transition technician: :ophthalmology_technician
    end

    event :technician_to_radiology_investigation do
      transition technician: :radiologist
    end

    event :technician_to_optician do
      transition technician: :optician
    end

    event :technician_to_pharmacist do
      transition technician: :pharmacist
    end

    event :technician_to_ophthalmology_technician do
      transition technician: :ophthalmology_technician
    end

    event :technician_to_radiologist do
      transition technician: :radiologist
    end

    event :technician_to_technician do
      transition technician: :technician
    end

    event :technician_to_incomplete do
      transition technician: :incomplete
    end

    event :ophthalmology_technician_to_technician do
      transition ophthalmology_technician: :technician
    end

    event :ophthalmology_technician_to_ophthalmology_technician do
      transition ophthalmology_technician: :ophthalmology_technician
    end

    event :ophthalmology_technician_to_radiologist do
      transition ophthalmology_technician: :radiologist
    end

    event :ophthalmology_technician_to_optician do
      transition ophthalmology_technician: :optician
    end

    event :ophthalmology_technician_to_pharmacist do
      transition ophthalmology_technician: :pharmacist
    end

    # events possible from radiology_investigation
    event :radiologist_to_receptionist do
      transition radiologist: :receptionist
    end

    event :radiologist_to_floormanager do
      transition radiologist: :floormanager
    end

    event :radiologist_to_cashier do
      transition radiologist: :cashier
    end

    event :radiologist_to_nurse do
      transition radiologist: :nurse
    end

    event :radiologist_to_doctor do
      transition radiologist: :doctor
    end

    event :radiologist_to_optometrist do
      transition radiologist: :optometrist
    end

    event :radiologist_to_ar_nct do
      transition radiologist: :ar_nct
    end

    event :radiologist_to_counsellor do
      transition radiologist: :counsellor
    end

    event :radiologist_to_optician do
      transition radiologist: :optician
    end

    event :radiologist_to_pharmacist do
      transition radiologist: :pharmacist
    end

    event :radiologist_to_ophthalmology_technician do
      transition radiologist: :ophthalmology_technician
    end

    event :radiologist_to_technician do
      transition radiologist: :technician
    end

    event :radiologist_to_incomplete do
      transition radiologist: :incomplete
    end

    event :radiologist_to_radiologist do
      transition radiologist: :radiologist
    end

    # cancel appointment
    event :cancel do
      transition [:not_arrived, :counsellor, :receptionist, :floormanager, :cashier, :nurse, :doctor, :optometrist,
                  :ar_nct, :incomplete, :away, :check_out, :call] => :cancelled
    end

    # mark patient Away
    event :doctor_to_away do
      transition doctor: :away
    end

    event :counsellor_to_away do
      transition counsellor: :away
    end

    event :receptionist_to_away do
      transition receptionist: :away
    end

    event :floormanager_to_away do
      transition floormanager: :away
    end

    event :cashier_to_away do
      transition cashier: :away
    end

    event :nurse_to_away do
      transition nurse: :away
    end

    event :optometrist_to_away do
      transition optometrist: :away
    end

    event :ar_nct_to_away do
      transition ar_nct: :away
    end

    event :ophthal_investigation_to_away do
      transition ophthal_investigation: :away
    end

    event :radiology_investigation_to_away do
      transition radiology_investigation: :away
    end

    event :laboratory_investigation_to_away do
      transition laboratory_investigation: :away
    end

    event :optical_to_away do
      transition optical: :away
    end

    event :pharmacy_to_away do
      transition pharmacy: :away
    end

    event :technician_to_away do
      transition technician: :away
    end

    event :radiologist_to_away do
      transition radiologist: :away
    end

    event :ophthalmology_technician_to_away do
      transition ophthalmology_technician: :away
    end

    event :pharmacist_to_away do
      transition pharmacist: :away
    end

    event :optician_to_away do
      transition optician: :away
    end

    # event :away do
    #   transition [:counsellor,:receptionist,:nurse,:optometrist] => :away
    # end
    # get Away patient
    event :away_to_optometrist do
      transition away: :optometrist
    end

    event :away_to_ar_nct do
      transition away: :ar_nct
    end

    event :away_to_cashier do
      transition away: :cashier
    end

    event :away_to_doctor do
      transition away: :doctor
    end

    event :away_to_counsellor do
      transition away: :counsellor
    end

    event :away_to_receptionist do
      transition away: :receptionist
    end

    event :away_to_floormanager do
      transition away: :floormanager
    end

    event :away_to_nurse do
      transition away: :nurse
    end

    event :away_to_ophthalmology_technician do
      transition away: :ophthalmology_technician
    end

    event :away_to_radiologist do
      transition away: :radiologist
    end

    event :away_to_technician do
      transition away: :technician
    end

    event :away_to_optician do
      transition away: :optician
    end

    event :away_to_pharmacist do
      transition away: :pharmacist
    end

    event :away_to_incomplete do
      transition away: :incomplete
    end

    # send to counsellor event
    event :send_to_counsellor do
      transition [:doctor, :receptionist, :floormanager, :cashier, :nurse, :optometrist, :ar_nct] => :counsellor
    end

    # non workflow engaged event
    event :waiting_to_engaged do
      transition waiting: :engaged
    end

    # send to incomplete event
    event :waiting_to_incomplete do
      transition waiting: :incomplete
    end

    event :engaged_to_incomplete do
      transition engaged: :incomplete
    end

    event :check_out_to_incomplete do
      transition check_out: :incomplete
    end

    event :call_to_incomplete do
      transition call: :incomplete
    end
  end

  def user(usr)
    self.user_id = usr
  end

  def transition_start
    self.transition_start = Time.current
  end

  def transition_end
    transition = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: id)[-1]
    transition.update(transition_end: Time.current) if transition.present?
    self.transition_end = nil
  end

  def away_transition_time
    away_time = 0
    away_transitions = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: id, to: 'away')
    unless away_transitions.empty?
      if (away_transitions.size == 1) && away_transitions[0].try(:transition_end).blank?
        away_time = TimeDifference.between(Time.current, away_transitions[0].transition_start).in_minutes
      elsif (away_transitions.size == 1) && away_transitions[0].try(:transition_end).present?
        away_time = TimeDifference.between(away_transitions[0].transition_end, away_transitions[0].transition_start)
                                  .in_minutes
      else
        away_transitions.each do |i|
          away_time += if i.transition_end.blank?
                         TimeDifference.between(Time.current, i.transition_start).in_minutes
                       else
                         TimeDifference.between(i.transition_end, i.transition_start).in_minutes
                       end
        end
      end
    end

    away_time
  end

  def total_transition_time_in_org
    total_time = ''
    begin
      set_end_time = end_time.nil? ? Time.now : end_time
      time_hash = TimeDifference.between(set_end_time, start_time).in_general
                                .delete_if { |unit, value| (value == 0 || ['hours', 'minutes'].exclude?(unit.to_s)) }
                                .stringify_keys
      time_hash = time_hash.merge(away_time_general) { |_k, v1, v2| v1 - v2 }
      if time_hash['minutes'].to_i < 0
        time_hash['hours'] -= 1 if time_hash['hours'].present?
        time_hash['minutes'] += 60
      end
      time_hash.each { |k, v| total_time += "#{v} #{k.upcase[0]} " }
      total_time = '0 M' if total_time.blank?
    rescue StandardError
      total_time = 'NA'
    end
    total_time
  end

  def  total_transition_time_in_epoch
    total_time = 0
    set_end_time = end_time.nil? ? Time.now : end_time
    time_diff = (set_end_time.to_f - start_time.to_f).to_i
  end

  def update_appointment_list_view
    opd_clinical_workflow_state_transitions.destroy_all if state == 'cancelled'
    @facility = Facility.find_by(id: facility_id.to_s)

    return unless @facility&.clinical_workflow

    current_state, current_state_color = current_state_options

    @appointment_list_view = AppointmentListView.find_by(appointment_id: appointment_id.to_s)
    @appointment_list_view&.update(current_state: current_state, current_state_color: current_state_color,
                                   appointment_engaged_time: Time.current)
  end

  def current_state_options
    if state == 'not_arrived'
      ['Scheduled', '#d9534f']
    elsif state == 'complete'
      ['Completed', '#5cb85c']
    elsif state == 'cancelled'
      ['Deleted', '#000']
    elsif state == 'incomplete'
      ['Incompleted', '#d9534f']
    else
      ['Engaged', '#ff8735']
    end
  end
end
