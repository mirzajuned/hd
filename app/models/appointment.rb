# 1  Metrics/ClassLength
# --
# 1  Total
class Appointment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  attr_accessor :skip_validation

  after_create :create_workflow, :create_appointment_list_view, :create_analytics_data
  after_update :update_workflow, :update_appointment_list_view, :update_analytics_data

  # after_create :create_integration_data, unless: :skip_validation
  # after_update :update_integration_data, unless: :skip_validation

  field :reason, type: String
  field :consultant_id, type: BSON::ObjectId
  field :scheduling_date, type: Date
  field :scheduling_time, type: Time # we are actually saving scheduled time, needs to be renamed
  field :appointmentdate, type: Date
  field :start_time, type: Time
  field :end_time, type: Time
  field :departmenttype, type: Integer
  field :appointmentstatus, type: Integer, default: 416774000

  field :reasonforcancellation, type: String

  field :arrived, type: BSON::Binary, default: false
  field :engaged, type: BSON::Binary, default: false
  field :seen, type: BSON::Binary, default: false

  field :arrived_time, type: Time
  field :engage_time, type: Time
  field :seen_time, type: Time

  field :waiting_time_min, type: Integer, default: 0
  field :engaged_time_min, type: Integer, default: 0
  field :total_time_min, type: Integer, default: 0

  field :created_from, type: String

  field :dilation_start_time, type: Time
  field :dilation_end_time, type: Time

  field :ref_doc_name, type: String
  field :ref_doc_place, type: String
  field :ref_doc_speciality, type: String
  field :ref_doc_number, type: String
  field :ref_doc_email, type: String
  field :ref_doc_city, type: String
  field :display_id, type: String

  field :patients_appointment_fees, type: String
  field :surgery_advised, type: Boolean, default: false

  field :referral_created_on, type: Date
  field :intra_referral_id, type: BSON::ObjectId
  field :opd_referral_id, type: BSON::ObjectId # instead of inter referral id we are saving opd_referral_id
  field :referral, type: Boolean, default: false
  field :referral_opd_record, type: BSON::ObjectId
  field :referral_type, type: String
  field :refer_to_facility_name, type: String
  field :referring_doctor, type: String
  field :referee_doctor, type: String
  field :referral_note, type: String
  field :referral_text, type: String
  field :patient_visit_category, type: String
  field :patient_category, type: String
  field :to_facility_name, type: String
  field :from_facility_name, type: String

  field :source_info, type: String
  field :newspaper_source_info, type: String
  # field :patient_name, type: String

  field :visit_no, type: Integer
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
  field :opd_consultation_taken, type: Boolean, default: false
  field :opd_consultation_amount, type: String
  field :opd_consultation_bill_type, type: String
  field :opd_consultation_bill_display_id, type: String

  # STATE MACHINE RUBY GEM VARIABLE AND NOT PART OF PATIENT PROFILE OR PATIENT OBJECT.
  # REFER STATE MACHINE GEM ON GITHUB FOR MORE INFO. STATE MACHINE IS STILL NOT IMPLEMENTED IN HG CODE.
  field :current_state, type: String

  # sub_appointment_types
  field :appointment_category_id, type: String
  field :appointmenttype, type: String, default: 'walkin' # to save walking vs appointment

  field :bkp_display_id, type: String
  embeds_many :sequences, class_name: '::Appointment::Sequence'

  state_machine :current_state, initial: :scheduled do
    event :patient_arrived do
      transition scheduled: :waiting
    end
    event :patient_engaged do
      transition waiting: :engaged
    end
    event :patient_seen do
      transition [:scheduled, :waiting, :engaged] => :seen
    end
    event :undo_arrived do
      transition waiting: :scheduled
    end
    # possible event for incomplete
    event :incomplete do
      transition [:waiting, :engaged] => :incomplete
    end
  end

  # SPACING LEFT INTENTIONALLY. ----------------------------------------------------

  # validates_uniqueness_of :integration_identifier

  # ASSOCIATIONS DEFINE HERE.
  has_one :patient_referral_type
  # has_one :opd_clinical_workflow

  belongs_to :patient
  belongs_to :user, index: { background: true }
  belongs_to :facility, index: { background: true }
  belongs_to :organisation, index: { background: true }
  belongs_to :department, index: { background: true }, optional: true
  belongs_to :appointment_type, optional: true
  belongs_to :case_sheet, optional: true

  has_many :appointmentassets

  accepts_nested_attributes_for :appointmentassets
  scope :created_on, lambda { |s, e, org|
    where(:appointmentstatus.nin => [89925002],
          :appointmentdate.gte => (Time.current.beginning_of_day - s.days).beginning_of_day,
          :appointmentdate.lte => (Time.current.end_of_day - e.days).end_of_day)
      .where(organisation_id: org)
      .where(:current_state.in => ['Engaged', 'Scheduled', 'Completed', 'Waiting',
                                   'Seen', 'engaged', 'scheduled', 'complete', 'waiting',
                                   'incomplete', 'seen'])
  }
  validates :start_time, presence: { message: 'start time cannot be blank' }

  scope :arrived, -> { where(arrived: true) }
  # AUTHORIZERS DEFINE HERE.
  include Authority::Abilities
  after_update :change_attributes_checked, if: proc {
    appointmentdate_changed? ||
      facility_id_changed? ||
      consultant_id_changed? ||
      appointment_type_id_changed? ||
      consultant_frozen_changed? ||
      scheduling_time_changed? ||
      start_time_changed? ||
      scheduling_date_changed?
  }
  self.authorizer_name = 'AppointmentAuthorizer'

  # def sk_validation
  #   return true
  # end

  before_save :set_integration_identifier

  def change_attributes_checked
    if appointmenttype == 'appointment' && appointmenttype != 'walkin'
      CommunicationNotificationJob.perform_now(
        'reschedule_appointment', id.to_s, self.class.to_s
      )
    end
  end

  def set_integration_identifier
    self.integration_identifier ||= BSON::ObjectId.new
  end

  def create_integration_data
    create_appointment = Appointment::Create.new
    @appointment = create_appointment.call(id.to_s)
  end

  def update_integration_data
    update_appointment = Appointment::Update.new
    @appointment = update_appointment.call(id.to_s)
  end

  def create_workflow
    Appointment::WorkflowOpd.new(self).create
  end

  def create_analytics_data
    Analytics::CreateService.call(id.to_s, user_id.to_s, facility_id.to_s, 'appointment')
  end

  def update_analytics_data
    # Analytics::UpdateService.call(self.id.to_s,self.user_id.to_s,self.facility_id.to_s,"appointment")
  end

  def update_workflow
    Appointment::WorkflowOpd.new(self).update
  end

  def create_appointment_list_view
    Appointment::NonWorkflowOpd.new(self).create
  end

  def update_appointment_list_view
    Appointment::NonWorkflowOpd.new(self).update
  end

  def current_facility_has_clinical_workflow
    facility.clinical_workflow
  end
end
