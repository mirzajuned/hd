class Inpatient::IpdRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  validates_presence_of :facility_id, :admission_id, :patient_id

  field :patient_entry_time, type: Time
  field :patient_exit_time, type: Time
  field :anesthesia_start_time, type: Time
  field :anesthesia_end_time, type: Time
  field :surgery_start_time, type: Time
  field :surgery_end_time, type: Time
  # field :discharge_date, type: Date
  # field :first_opd_visit, type: Date
  # field :complaint_date, type: Date
  field :print_procedure, type: Boolean, default: true
  field :print_investigation, type: Boolean, default: true
  field :print_implant, type: Boolean, default: true
  # valid attribtes
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :admission_id, type: BSON::ObjectId
  field :is_deleted, type: Boolean, default: false
  # field :patient_id,type: BSON::ObjectId

  #check advised
  field :no_opthalmic_history_advised, type: Boolean, default: false
  field :no_systemic_history_advised, type: Boolean, default: false
  field :no_allergy_advised, type: Boolean, default: false

  # ophthalmic slect
  field :speciality_histories, type: String
  field :personal_histories, type: String
  field :antimicrobial_agents, type: String
  field :drug_allergies, type: String
  field :drug_allergies_comment, type: String
  field :antifungal_agents, type: String
  field :antiviral_agents, type: String
  field :nsaids, type: String
  field :eye_drops, type: String
  field :contact_allergies, type: String
  field :contact_allergies_comment, type: String
  field :food_allergies, type: String
  field :food_allergies_comment, type: String
  field :is_migrated, type: Boolean, default: true

  field :specialty_id, type: String

  field :clinical_data_present, type: Boolean, default: false

  # has many ot schedule
  has_and_belongs_to_many :ots, class_name: '::OtSchedule', inverse_of: nil
  belongs_to :patient
  belongs_to :admission

  belongs_to :case_sheet, optional: true

  # default scop# e
  default_scope -> { where(is_deleted: false) }

  embeds_many :treatmentmedication, class_name: '::MedicationRecord' # medications
  embeds_many :record_histories
  embeds_many :inventorymedication, class_name: '::Inpatient::InventoryMedication'
  embeds_many :inventoryconsumables, class_name: '::Inpatient::InventoryConsumable'
  embeds_many :inventorypack, class_name: '::Inpatient::InventoryPack'
  embeds_many :inventoryprep, class_name: '::Inpatient::InventoryPrep'
  embeds_many :inventorydressings, class_name: '::Inpatient::InventoryDressing'
  embeds_many :inventoryinstrument, class_name: '::Inpatient::InventoryInstrument'
  embeds_many :inventoryimplants, class_name: '::Inpatient::InventoryImplant'
  embeds_many :inventoryswabs, class_name: '::Inpatient::InventorySwab'
  # embeds_one :admission_note,class_name: "::AdmissionNote"
  embeds_one :clinical_note, class_name: '::ClinicalNote'
  embeds_many :operative_notes, class_name: '::OperativeNote', cascade_callbacks: true
  embeds_one :discharge_note, class_name: '::DischargeNote'
  embeds_many :ward_notes, class_name: '::WardNote'
  embeds_many :diagnosislist, class_name: '::Diagnosis'
  embeds_many :procedure, class_name: '::Procedure'
  embeds_many :complications, class_name: '::Complication'
  embeds_many :bill_of_material, class_name: '::Inpatient::Bom'

  # embeds of histories
  embeds_many :allergy_histories, class_name: '::AllergyHistory', cascade_callbacks: true
  embeds_many :personal_history_records, class_name: '::PersonalHistoryRecord', cascade_callbacks: true
  embeds_many :speciality_history_records, class_name: '::SpecialityHistoryRecord', cascade_callbacks: true
  embeds_one :other_history, class_name: '::OtherHistory', inverse_of: :project, autobuild: true, cascade_callbacks: true
  embeds_one :lens_history, class_name: '::LensHistory', inverse_of: :project, autobuild: true, cascade_callbacks: true
  embeds_one :paediatrics_history, class_name: '::PaediatricsHistory', autobuild: true, cascade_callbacks: true
  # end

  # nested_attributes
  accepts_nested_attributes_for :personal_history_records, allow_destroy: true
  accepts_nested_attributes_for :speciality_history_records, allow_destroy: true
  accepts_nested_attributes_for :allergy_histories, allow_destroy: true
  accepts_nested_attributes_for :other_history, allow_destroy: true
  accepts_nested_attributes_for :lens_history, allow_destroy: true
  accepts_nested_attributes_for :paediatrics_history, allow_destroy: true
  accepts_nested_attributes_for :bill_of_material, allow_destroy: true
  # end

  embeds_many :record_histories
  embeds_many :ophthal_investigations_list, class_name: '::OphthalmologyInvestigation' # OphthalmologyInvestigation
  embeds_many :radiology_investigations_list, class_name: '::RadiologyInvestigation' # rads
  embeds_many :laboratory_investigations_list, class_name: '::LaboratoryInvestigation' # labs

  accepts_nested_attributes_for :ophthal_investigations_list, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :radiology_investigations_list, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :laboratory_investigations_list, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true

  accepts_nested_attributes_for :treatmentmedication, reject_if: proc { |attributes| attributes['medicinename'].empty? }, allow_destroy: true # medications
  accepts_nested_attributes_for :inventorymedication, reject_if: proc { |attributes| attributes['name'].empty? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryconsumables, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventorypack, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryprep, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventorydressings, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryinstrument, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryimplants, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryswabs, class_name: '::Inpatient::InventorySwab', reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true

  accepts_nested_attributes_for :clinical_note, class_name: '::ClinicalNote'
  accepts_nested_attributes_for :operative_notes, class_name: '::OperativeNote'
  accepts_nested_attributes_for :discharge_note, class_name: '::DischargeNote'
  accepts_nested_attributes_for :ward_notes, class_name: '::WardNote'

  accepts_nested_attributes_for :diagnosislist, class_name: '::Diagnosis', allow_destroy: true, reject_if: proc { |attributes| attributes['diagnosisname'].blank? }
  accepts_nested_attributes_for :procedure, class_name: '::Procedure', allow_destroy: true, reject_if: proc { |attributes| attributes['procedurename'].blank? }

  accepts_nested_attributes_for :complications, class_name: '::Complication', allow_destroy: true, reject_if: proc { |attributes| attributes['complication_name'].blank? }

  accepts_nested_attributes_for :patient, class_name: '::Patient'
  accepts_nested_attributes_for :admission, class_name: '::Admission'

  def compute_medication_stop_duration(duration, durationoption)
    if durationoption == 'D'
      (Date.current + duration.to_s.to_f.day)
    elsif durationoption == 'W'
      (Date.current + duration.to_s.to_f.week)
    elsif durationoption == 'M'
      (Date.current + duration.to_s.to_i.month)
    end
  end

  def checkboxes_checked(checked)
    checked&.split(',')
  end

  def excluded_procedure?(operative_note_id, procedure)
    procedure.is_performed && (procedure.performed_note_id.to_s != operative_note_id)
  rescue StandardError
    false
  end
end
