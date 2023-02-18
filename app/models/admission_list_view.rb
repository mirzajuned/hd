# No Offenses
class AdmissionListView
  include Mongoid::Document
  include Mongoid::Timestamps

  # Patient
  field :patient_id, type: BSON::ObjectId
  field :patient_name, type: String
  field :patient_display_id, type: String
  field :patient_mr_no, type: String
  field :patient_age, type: String
  field :patient_gender, type: String
  field :patient_type, type: String
  field :patient_type_color, type: String

  # Admission
  field :admitting_doctor, type: String
  field :admitting_doctor_id, type: BSON::ObjectId
  field :admission_display_id, type: String
  field :admission_date, type: Date, default: Date.today
  field :admission_time, type: Time #, default: Time.now
  field :discharge_date, type: Date
  field :discharge_time, type: Time
  field :admission_type, type: String, default: 'planned'
  field :reason_for_admission, type: String

  # Ward
  field :daycare, type: Boolean
  field :ward_name, type: String
  field :ward_code, type: String
  field :room_name, type: String
  field :room_code, type: String
  field :bed_name, type: String
  field :bed_code, type: String

  # Workflow
  field :current_state, type: String, default: 'Scheduled'
  field :current_state_color, type: String

  # AdmissionStage
  field :admission_stage, type: String, default: 'pre_admission'

  # # StateMachine
  field :user_id, type: BSON::ObjectId
  field :department_id, type: String
  field :start_time, type: DateTime, default: Time.current
  field :end_time, type: DateTime
  field :message, type: String

  # Insurance
  field :insurance_state, type: String
  field :insurance_badge_color, type: String
  field :tpa_state, type: String

  # Specialty
  field :specialty_id, type: String
  field :specialty_name, type: String
  field :age, type: Integer

  field :city, type: String
  field :pincode, type: String
  field :state, type: String
  field :district, type: String
  field :commune, type: String
  field :patient_mobilenumber, type: String
  field :is_migrated, type: Boolean, default: true

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  # OT Store
  field :is_tray_created, type: Boolean, default: false

  embeds_many :admission_state_transitions
  embeds_many :admission_milestones

  belongs_to :admission

  state_machine initial: :scheduled, attribute: :sm_state do
    audit_trail initial: false, class: AdmissionStateTransition,
                context: [:user_id, :department_id, :start_time, :end_time, :message]

    before_transition do |admission, transition|
      args = transition.args
      raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 3)" if args.length != 3

      admission.admission_list_fields(transition, args)
    end

    event :assign_to_receptionist do
      transition any => :receptionist
    end

    event :assign_to_nurse do
      transition any => :nurse
    end

    event :assign_to_doctor do
      transition any => :doctor
    end

    event :assign_to_counsellor do
      transition any => :counsellor
    end

    event :assign_to_tpa do
      transition any => :tpa
    end

    event :discharge do
      transition any => :discharged
    end
  end

  def admission_list_fields(transition, args)
    self.user_id = args[1] == 'user' ? args[0] : nil
    self.department_id = args[1] == 'department' ? args[0] : nil
    self.start_time = Time.current
    self.end_time = transition.event != 'discharge' ? nil : Time.current
    self.message = args[2]
    admission_state_transitions[-1]&.update(end_time: Time.current)
  end
end
