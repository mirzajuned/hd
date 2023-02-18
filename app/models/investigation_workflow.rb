class InvestigationWorkflow
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :state, type: String
  field :patient_id, type: String
  field :organisation_id, type: String
  field :facility_id, type: String
  field :user_id, type: String
  field :assessment_id, type: String
  # field :appointmentdate, type: Date
  # field :doctor_ids, type:  Array,default: []
  field :_type, type: String
  field :end_time, type: Time
  field :start_time, type: Time

  # associations
  has_one :appointment, :class_name => 'Appointment'
  # state machine
  state_machine :initial => :no_investigations do
    audit_trail initial: false
    event :advised do
      transition :no_investigations => :advised
    end
    # events possible from receptionists
    event :advised_to_payment do
      transition :advised => :payment_done
    end

    event :patient_not_arrived do
      transition :advised => :patient_not_arrived
    end

    event :payment_done_to_technician do
      transition :payment_done => :technician
    end

    # event :technician_to_laboratory do
    #   transition :technician => :laboratory
    # end

    # event :technician_to_radiology do
    #   transition :technician => :radiology
    # end

    # event :technician_to_ophthal do
    #   transition :technician => :ophthal
    # end
    # events possible from investigator

    event :start_investigation do
      transition :technician => :investigation_started
    end

    # complete or end investigation
    event :upload_complete do
      transition :investigation_started => :upload_completed
    end

    event :investigation_completed do
      transition :upload_completed => :seen_by_doctor
    end

    # undo complete
    # event :verified do
    #   transition :complete => :receptionist
    # end
  end
end
