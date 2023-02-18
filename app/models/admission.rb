# No Offenses
class Admission
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  after_create :create_analytics_data
  after_save :admission_list_view, :ot_list_view
  after_update :update_ipd_record, :update_analytics_data, if: :is_deleted_changed?

  field :is_migrated, type: Boolean, default: true
  field :is_insured, type: String, default: 'No'
  field :insurance_name, type: String
  field :tpa_name, type: String
  field :insurance_comments, type: String
  field :tpa_contact_id, type: BSON::ObjectId
  field :insurance_contact_id, type: BSON::ObjectId

  field :doctor, type: BSON::ObjectId
  field :anesthesia, type: String
  field :doctor_1, type: BSON::ObjectId
  field :doctor_2, type: BSON::ObjectId
  field :doctor_3, type: BSON::ObjectId
  field :patient_insurance_id, type: BSON::ObjectId
  field :admission_type, type: String
  field :admissionreason, type: String
  field :scheduled_date, type: Date, default: Date.current
  field :scheduled_time, type: Time, default: Time.current
  field :admissiondate, type: Date, default: Date.current
  field :admissiontime, type: Time, default: Time.current
  field :dischargedate, type: Date
  field :dischargetime, type: Time
  field :reporting_date, type: Date, default: Date.current
  field :reporting_time, type: Time
  field :isdischarged, type: Boolean, default: false
  field :marked_for_discharged, type: Boolean, default: false
  field :daycare, type: Boolean, default: true
  field :managementplan, type: String
  field :insurance_status, type: String
  field :patient_arrived, type: Boolean, default: false
  field :ready_for_admission, type: Boolean, default: false
  field :ready_for_ot, type: Boolean, default: false
  field :display_id, type: String
  field :is_deleted, type: Boolean, default: false
  field :department_id, type: String
  field :approved_amount, type: Integer
  field :bracket_amount, type: Integer
  field :clinical_findings, type: String
  field :current_company_name, type: String

  field :patient_visit_category, type: String
  field :patient_category, type: String
  field :integration_identifier, type: BSON::ObjectId
  field :created_from, type: String # 'Integration' for integration data

  field :insurance_policy_no, type: String # policy no of patient insurance
  field :insurance_policy_expiry_date, type: Date

  # Documents For Cashless
  field :document_passport, type: Boolean
  field :document_insurancecard, type: Boolean
  field :document_government_id, type: Boolean
  field :document_employeecard, type: Boolean
  field :document_others, type: Boolean
  # India
  field :document_aadharcard, type: Boolean
  field :document_electioncard, type: Boolean
  field :document_drivinglicense, type: Boolean
  field :document_patient_cancelled_cheque, type: Boolean
  # Vietnam
  field :document_vss, type: Boolean
  field :cleared_for_discharge, type: Boolean, default: false

  field :document_tpa_form, type: Boolean

  field :specialty_id, type: String
  field :ipd_templates_count, type: Integer, default: 0

  field :admission_stage, type: String, default: 'pre_admission'

  field :admission_in_progress, type: Boolean, default: false

  field :bkp_display_id, type: String
  embeds_many :sequences, class_name: '::Admission::Sequence'

  embeds_many :admission_milestones
  accepts_nested_attributes_for :admission_milestones, allow_destroy: true

  belongs_to :patient
  belongs_to :organisation, optional: true
  belongs_to :facility
  belongs_to :user, optional: true
  belongs_to :case_sheet, optional: true
  belongs_to :ward, optional: true
  belongs_to :room, optional: true
  belongs_to :bed, optional: true

  has_many :ot_schedules

  # validates_presence_of :reporting_date, :reporting_time, if: :new_record?

  validate :unique_admission_date
  validate :unique_admission_doctor

  def unique_admission_date
    admission = Admission.find_by(:id.ne => id, admissiondate: admissiondate, patient_id: patient_id, is_deleted: false)
    return unless admission.present?

    errors.add(:admissiondate, '- An admission already exists on the same date.')
  end

  def unique_admission_doctor
    if (( doctor == doctor_1 ||  doctor == doctor_2 || doctor == doctor_3 ) ||
        ( (doctor_1 == doctor_2 && doctor_1.to_s != '' ) || (doctor_1 == doctor_3 && doctor_1.to_s != '' ) ) || ( doctor_2 == doctor_3 && doctor_2.to_s != '' ))
      errors.add(:doctor, '- Duplicate Doctors.')
    end
  end

  before_save :set_integration_identifier
  def set_integration_identifier
    self.integration_identifier ||= BSON::ObjectId.new
  end

  def set_bed_details
    @ward = Ward.find_by(id: ward_id) if ward_id
    @room = Room.find_by(id: room_id) if room_id
    @bed = Room.find_by(id: room_id).beds.find_by(id: bed_id) if bed_id
    [@ward, @room, @bed]
  end

  def admission_list_view
    admission_list_view = AdmissionListView.find_by(admission_id: id.to_s)
    if admission_list_view.present?
      AdmissionListViews::UpdateService.call(admission_list_view, self)
    else
      AdmissionListViews::CreateService.call(self)
    end
  end

  def ot_list_view
    ot_list_views = OtListView.where(admission_id: id)
    ot_list_views.each do |ot_list_view|
      ot_schedule = OtSchedule.find_by(id: ot_list_view.ot_id)
      OtListViews::UpdateService.call(ot_list_view, ot_schedule)
    end
  end

  def update_ipd_record
    @ipd_record = Inpatient::IpdRecord.find_by(admission_id: id)
    @ipd_record.update_attributes(is_deleted: is_deleted)
  end

  def create_analytics_data
    Analytics::CreateService.call(id.to_s, user_id.to_s, facility_id.to_s, 'admission')
  end

  def update_analytics_data
    Analytics::UpdateService.call(id.to_s, user_id.to_s, facility_id.to_s, 'admission')
  end
end
