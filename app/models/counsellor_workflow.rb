class CounsellorWorkflow
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :state, type: String
  field :tpa_state, type: String
  field :patient_id, type: String
  field :organisation_id, type: String
  field :facility_id, type: String
  field :user_id, type: String
  field :adviseddate, type: Date
  field :doctor_ids, type: Array, default: []
  field :_type, type: String
  field :end_time, type: Time
  field :start_time, type: Time
  field :patient_name, type: String
  field :followupdates, type: Array, default: []
  field :surgerydates, type: Array, default: []
  field :counsellingdate, type: Date
  field :appointmentdate, type: Date
  field :converted_state, type: Array, default: ["Converted"]
  field :appointment_type_comment, type: String
  field :patient_type, type: String
  field :patient_type_color, type: String

  field :token_number, type: String
  field :in_department, type: Boolean, default: false
  field :with_user, type: String
  field :with_user_role, type: String
  field :with_department, type: String

  # associations
  has_one :appointment, :class_name => 'Appointment'
  # state machine
  state_machine :initial => :advised do
    audit_trail initial: false

    event :arrived do
      transition :advised => :arrived
    end

    event :arrived_to_counselling_done do
      transition :arrived => :counselling_done
    end
    # events possible from after counselling
    event :counselling_done_to_followup do
      transition :counselling_done => :followup
    end
    event :counselling_done_to_surgery_scheduled do
      transition :counselling_done => :surgery_scheduled
    end
    event :counselling_done_to_cancelled do
      transition :counselling_done => :cancelled
    end
    event :counselling_done_to_converted do
      transition :counselling_done => :converted
    end

    event :converted do
      transition [:advised, :arrived, :followup, :counselling_done, :cancelled] => :converted
    end

    event :cancelled do
      transition [:followup, :converted, :counselling_done] => :cancelled
    end

    event :followup do
      transition [:converted, :counselling_done, :cancelled] => :followup
    end

    event :undo_converted do
      transition [:converted] => :counselling_done
    end

    event :undo_cancel do
      transition  :cancelled => :counselling_done
    end

    event :deleted do
      transition [:advised, :followup, :converted, :counselling_done] => :deleted
    end
  end
end
