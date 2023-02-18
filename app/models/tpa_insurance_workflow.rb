class TpaInsuranceWorkflow
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :state, type: String
  field :tpa_admission_doctor, type: String
  field :tpa_admission_date, type: Date
  field :admission_status, type: String # , default: 'in_process'
  field :patient_id, type: BSON::ObjectId
  field :tpa_user_id, type: BSON::ObjectId
  field :appointment_id, type: BSON::ObjectId
  field :admission_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :start_time, type: Time
  field :end_time, type: Time
  field :patient_name, type: String
  field :initiation_date, type: Date
  field :followupdates, type: Date
  field :patient_type, type: String
  field :patient_type_color, type: String
  field :admissions_linked, type: Array, default: []
  field :is_deleted, type: Boolean

  # associations
  has_many :tpa_insurance_workflow_state_transitions
  # has_one :patient,:class_name => 'Patient'

  # state machine
  state_machine :initial => :initiated do
    audit_trail initial: false, context: [:tpa_user_id]

    event :pre_auth do
      transition :initiated => :pre_auth
    end

    event :pre_auth_final_approval do
      transition :pre_auth_approved => :pre_auth_final_approval
    end

    event :tpa_final_payment do
      transition :pre_auth_final_approval => :tpa_final_payment
    end

    event :tpa_payment_received do
      transition :tpa_final_payment => :tpa_payment_received
    end

    event :pre_auth_query do
      transition :pre_auth => :pre_auth_query
    end

    event :pre_auth_approved do
      transition [:pre_auth, :pre_auth_query] => :pre_auth_approved
    end

    event :pre_auth_declined do
      transition [:pre_auth, :pre_auth_query] => :pre_auth_declined
    end

    event :tpa_process_ended do
      transition [:initiated, :pre_auth, :pre_auth_approved, :pre_auth_query, :pre_auth_declined] => :tpa_process_ended
    end

    # in-case when patient admission got deleted
    event :workflow_deleted do
      transition [:initiated, :pre_auth, :pre_auth_approved, :pre_auth_final_approval, :tpa_final_payment, :tpa_payment_received, :pre_auth_query, :pre_auth_declined, :tpa_process_ended] => :workflow_deleted
    end
  end
end

# indexes on this model's fields

# db.tpa_insurance_workflows.createIndex({ appointment_id: 1 })
# db.tpa_insurance_workflows.createIndex({ admission_id: 1 })
# db.tpa_insurance_workflows.createIndex({ facility_id: 1 })
