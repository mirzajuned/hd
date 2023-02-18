# 1  Metrics/ClassLength
# --
# 1  Total
class ProvisionalAppointment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  attr_accessor :skip_validation

  # after_create :create_workflow, :create_appointment_list_view, :create_analytics_data
  # after_update :update_workflow, :update_appointment_list_view, :update_analytics_data

  # after_create :create_integration_data, unless: :skip_validation
  # after_update :update_integration_data, unless: :skip_validation

  # Patient Personal Details
  field :firstname, type: String
  field :middlename, type: String
  field :lastname, type: String
  field :mobilenumber, type: String
  field :salutation, type: String
  field :gender, type: String
  field :age, type: Integer
  field :age_month, type: Integer
  field :dob, type: Date
  field :email, type: String

  # Patient Address
  field :address_1, type: String
  field :address_2, type: String
  field :district, type: String
  field :commune, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: Integer

  # Appointment Details
  field :reason, type: String
  field :consultant_id, type: BSON::ObjectId
  field :scheduling_date, type: Date, default: Date.current
  field :scheduling_time, type: Time, default: Time.current
  field :appointmentdate, type: Date
  field :start_time, type: Time
  field :end_time, type: Time
  field :departmenttype, type: Integer

  field :reasonforcancellation, type: String

  field :is_deleted, type: Boolean, default: false
  field :converted, type: Boolean, default: false

  field :created_from, type: String

  # field :display_id, type: String

  field :is_migrated, type: Boolean, default: true

  field :token_number, type: String
  field :specialty_id, type: String

  field :consultancy_type, type: String # h1.001 -> Free, h1.002 -> Paid
  field :consultancy_type_reason, type: String
  field :consultancy_type_by, type: String

  field :opd_record_count, type: Integer, default: 0

  # INTEGRATION
  field :integration_identifier, type: BSON::ObjectId

  field :consultant_frozen, type: Boolean, default: false

  # STATE MACHINE RUBY GEM VARIABLE AND NOT PART OF PATIENT PROFILE OR PATIENT OBJECT.
  # REFER STATE MACHINE GEM ON GITHUB FOR MORE INFO. STATE MACHINE IS STILL NOT IMPLEMENTED IN HG CODE.
  field :current_state, type: String

  # sub_appointment_types
  field :appointment_category_id, type: String
  field :appointmenttype, type: String, default: 'appointment' # to save walking vs appointment

  field :appointment_id, type: BSON::ObjectId

  # state_machine :current_state, initial: :scheduled do
  #   event :patient_arrived do
  #     transition scheduled: :waiting
  #   end
  #   event :patient_engaged do
  #     transition waiting: :engaged
  #   end
  #   event :patient_seen do
  #     transition [:scheduled, :waiting, :engaged] => :seen
  #   end
  #   event :undo_arrived do
  #     transition waiting: :scheduled
  #   end
  #   # possible event for incomplete
  #   event :incomplete do
  #     transition [:waiting, :engaged] => :incomplete
  #   end
  # end

  # SPACING LEFT INTENTIONALLY. ----------------------------------------------------

  # validates_uniqueness_of :integration_identifier

  # ASSOCIATIONS DEFINE HERE.
  # has_one :patient_referral_type
  # has_one :opd_clinical_workflow

  validates :start_time, presence: { message: 'cannot be blank' }
  # AUTHORIZERS DEFINE HERE.
  include Authority::Abilities

  before_save :set_integration_identifier
  def set_integration_identifier
    self.integration_identifier ||= BSON::ObjectId.new
  end

  # def create_integration_data
  #   create_appointment = Appointment::Create.new
  #   @appointment = create_appointment.call(id.to_s)
  # end
  #
  # def update_integration_data
  #   update_appointment = Appointment::Update.new
  #   @appointment = update_appointment.call(id.to_s)
  # end
end
