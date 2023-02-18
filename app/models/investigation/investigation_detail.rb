class Investigation::InvestigationDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  after_save :clear_redis_cache

  # Entered Details
  field :entered_by, type: BSON::ObjectId
  field :entered_by_username, type: String
  field :entered_at, type: DateTime
  field :entered_at_facility_id, type: BSON::ObjectId
  field :entered_at_facility_name, type: String

  # Advised Details
  field :requested_by, type: String # Patient || User
  field :requesting_user_id, type: BSON::ObjectId
  field :advised_by, type: BSON::ObjectId
  field :advised_by_username, type: String
  field :advised_at, type: DateTime
  field :advised_at_facility_id, type: BSON::ObjectId
  field :advised_at_facility_name, type: String
  field :ehr_investigation_record_id, type: BSON::ObjectId
  field :investigation_record_id, type: BSON::ObjectId
  field :investigation_side, type: String
  # Couselling Details
  field :counselled_by, type: BSON::ObjectId
  field :counselled_by_username, type: String
  field :counselled_at, type: DateTime
  field :counselled_at_facility_id, type: BSON::ObjectId
  field :counselled_at_facility_name, type: String

  # Payment Details
  field :payment_done, type: Boolean
  field :bill_number, type: String
  field :invoice_id, type: BSON::ObjectId
  field :collected_by, type: BSON::ObjectId
  field :collected_by_username, type: String
  field :collected_at, type: DateTime
  field :collected_at_facility_id, type: BSON::ObjectId
  field :collected_at_facility_name, type: String

  # Performed Details
  field :performed_outside, type: Boolean
  field :performed_outside_by, type: String
  field :performed_from, type: String
  field :performed_by, type: BSON::ObjectId
  field :performed_by_username, type: String
  field :performed_at, type: DateTime
  field :performed_at_facility_id, type: BSON::ObjectId
  field :performed_at_facility_name, type: String
  field :date_performed_at, type: Date

  # Send Outside
  field :sent_outside_by, type: BSON::ObjectId
  field :sent_outside_by_username, type: String
  field :sent_outside_at, type: DateTime
  field :sent_outside_at_facility_id, type: BSON::ObjectId
  field :sent_outside_at_facility_name, type: String

  # Tempalate Details
  field :template_created_by, type: BSON::ObjectId
  field :template_created_by_username, type: String
  field :template_created_at, type: DateTime
  field :template_created_at_facility_id, type: BSON::ObjectId
  field :template_created_at_facility_name, type: String

  # Reviewed Details
  field :reviewed_by, type: BSON::ObjectId
  field :reviewed_by_username, type: String
  field :reviewed_at, type: DateTime
  field :reviewed_at_facility_id, type: BSON::ObjectId
  field :reviewed_at_facility_name, type: String

  # Start Test Time
  field :test_started_by, type: BSON::ObjectId
  field :test_started_by_username, type: String
  field :started_test_at, type: DateTime
  field :started_test_at_facility_id, type: BSON::ObjectId
  field :started_test_at_facility_name, type: String

  # Removed Details
  field :removing_reason, type: String
  field :removed_by, type: BSON::ObjectId
  field :removed_by_username, type: String
  field :removed_at, type: DateTime
  field :removed_at_facility_id, type: BSON::ObjectId
  field :removed_at_facility_name, type: String
  field :date_removed_at, type: Date

  # Declined Details
  field :declined_by, type: BSON::ObjectId
  field :declined_by_username, type: String
  field :declined_at, type: DateTime
  field :declined_at_facility_id, type: BSON::ObjectId
  field :declined_at_facility_name, type: String
  field :date_declined_at, type: Date

  # Other Reference ID
  field :opd_record_id, type: BSON::ObjectId
  field :appointment_id, type: BSON::ObjectId
  field :opd_investigation_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :investigation_patient_opd_record_id, type: BSON::ObjectId

  # Flags
  field :is_deleted, type: Boolean, default: false
  field :is_custom, type: Boolean, default: false

  # Workflow State
  field :previous_state, type: Array, default: []
  field :state, type: String # Advised -> PaymentDone -> Test Started -> Test Completed -> Report Generated -> Test Reviewed -> Perfomed
  field :state_date_time, type: DateTime

  field :evaluation_data, type: Hash

  # Doctor's Remark
  field :upload_remark, type: String

  #fields for mis reports
  field :specialization, type: String
  field :patient_fullname, type: String
  field :patient_mobilenumber, type: String
  field :patient_display_id, type: String
  field :patient_mrno, type: String
  field :patient_location, type: String
  field :patient_gender, type: String #filter 
  field :patient_age, type: Integer #filter 
  field :patient_exact_age, type: Integer
  field :patient_district, type: String
  field :patient_commune, type: String
  field :patient_city, type: String
  field :patient_state, type: String
  field :patient_pincode, type: Integer
  field :patient_location_id, type: BSON::ObjectId
  field :patient_area_manager_id, type: BSON::ObjectId
  field :patient_area_manager_name, type: String
  field :patient_pincode, type: Integer
  field :order_item_advised_id, type: BSON::ObjectId

  belongs_to :patient, optional: true
  belongs_to :queue, class_name: "::Investigation::Queue", optional: true

  belongs_to :case_sheet, optional: true

  # State Machine
  # Case 1 : Patient Performed the Test Outside
  # Case 2 : Test to be Performed
  # Case 3 : Test Cancelled
  state_machine :state, :initial => :advised do
    before_transition any => any, :do => :update_previous_state

    event :counselled do
      transition [:advised, :declined, :payment_taken] => :counselled
    end

    event :performed do
      transition [:advised, :declined, :counselled, :payment_taken, :sent_outside, :test_started] => :performed
    end

    event :removed do
      transition [:advised, :counselled] => :removed
    end

    event :declined do
      transition [:advised, :counselled, :payment_taken] => :declined
    end

    event :payment_taken do
      transition [:advised, :declined, :counselled] => :payment_taken
    end

    event :sent_outside do
      transition :payment_taken => :sent_outside
    end

    event :test_started do
      transition :payment_taken => :test_started
    end

    event :template_created do
      transition :performed => :template_created
    end

    event :reviewed do
      transition [:template_created, :performed] => :reviewed
    end

    # event :document_uploaded do
    #   transition :performed => :document_uploaded
    # end
  end

  # Used By StateMachine
  def update_previous_state
    prev_state = previous_state
    prev_state << state
    update(previous_state: prev_state)
  end

  def clear_redis_cache
    # $REDIS.del("investigation_queue:#{self.queue_id}")
    Redis::Master.new.del("investigation_queue:#{queue_id}")
  end
end
