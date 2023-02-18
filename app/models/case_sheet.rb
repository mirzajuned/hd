class CaseSheet
  include Mongoid::Document
  include Mongoid::Timestamps

  before_save :set_case_id

  field :case_id, type: String
  field :case_name, type: String

  field :patient_age, type: String
  field :patient_gender, type: String

  field :specialty_id, type: String

  field :appointment_ids, type: Array, default: []
  field :admission_ids, type: Array, default: []
  field :ot_schedule_ids, type: Array, default: []
  field :opd_record_ids, type: Array, default: []
  field :counsellor_record_ids, type: Array, default: []
  field :ipd_record_ids, type: Array, default: []

  field :active_admission_id, type: BSON::ObjectId

  field :free_form_histories, type: Hash, default: {}
  field :free_form_examinations, type: Hash, default: {}
  field :free_form_diagnoses, type: Hash, default: {}
  field :free_form_procedures, type: Hash, default: {}
  field :free_form_complications, type: Hash, default: {}
  field :free_form_investigations, type: Hash, default: {}
  field :provisional_diagnosis, type: Hash, default: {}

  field :is_active, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: true
  field :case_switchable_opd, type: Hash, default: {}
  field :case_switchable_ipd, type: Hash, default: {}

  field :start_date, type: DateTime, default: Time.current

  field :counsellor_patient_discussions, type: Hash, default: {}
  field :patient_surgery_packages, type: Hash, default: {}
  field :latest_surgery_package, type: Hash, default: {}

  field :created_by_id, type: BSON::ObjectId
  field :updated_by_id, type: BSON::ObjectId

  field :bkp_case_id, type: String
  embeds_many :sequences, class_name: '::CaseSheet::Sequence'

  belongs_to :patient, optional: true
  belongs_to :organisation, optional: true

  embeds_many :chief_complaints, class_name: '::ChiefComplaint'
  embeds_many :diagnoses, class_name: '::Diagnosis'
  embeds_many :procedures, class_name: '::Procedure'
  embeds_many :complications, class_name: '::Complication'
  embeds_many :ophthal_investigations, class_name: '::OphthalmologyInvestigation'
  embeds_many :laboratory_investigations, class_name: '::LaboratoryInvestigation'
  embeds_many :radiology_investigations, class_name: '::RadiologyInvestigation'

  validates_presence_of :start_date

  def set_case_id
    return unless organisation.present?

    self.bkp_case_id ||= CommonHelper.get_case_id(organisation)
  end

  # Indexes
  # index({ created_at: 1 }) # db.case_sheets.createIndex({ created_at: 1 })
  # index({ patient_id: 1 }) # db.case_sheets.createIndex({ patient_id: 1 })
  # index({ appointment_ids: 1 }) # db.case_sheets.createIndex({ appointment_ids: 1 })
  # for conversion query
  # index({ organisation_id: 1 }) # db.case_sheets.createIndex({ organisation_id: 1 })
  # db.case_sheets.createIndex({ "ophthal_investigations.order_item_advised_id": 1 })
  # db.case_sheets.createIndex({ "radiology_investigations.order_item_advised_id": 1 })
  # db.case_sheets.createIndex({ "laboratory_investigations.order_item_advised_id": 1 })
  # db.case_sheets.createIndex({ "procedures.order_item_advised_id": 1 })
  # db.case_sheets.createIndex({ "procedures.order_item_id": 1 })
  # db.case_sheets.createIndex({ "radiology_investigations.advised_at_facility_id": 1,
  #                              "radiology_investigations.advised_datetime": 1 },
  #                            { name: "radiology_date_wise_index" })
  # db.case_sheets.createIndex({ "procedures.advised_at_facility_id": 1, "procedures.advised_datetime": 1 },
  #                            {name: "procedure_date_wise_index" })
  # db.case_sheets.createIndex({ "ophthal_investigations.advised_at_facility_id": 1,
  #                              "ophthal_investigations.advised_datetime": 1 },
  #                            { name: "ophthal_date_wise_index" })
  # db.case_sheets.createIndex({ "laboratory_investigations.advised_at_facility_id": 1,
  #                              "laboratory_investigations.advised_datetime": 1 },
  #                            { name: "laboratory_date_wise_index" })
  # for doctor and counsellor wise query
  # db.case_sheets.createIndex({ "radiology_investigations.advised_at_facility_id": 1,
  #                              "radiology_investigations.counselled_datetime": 1 },
  #                            { name: "radiology_counselled_date_wise_index" })
  # db.case_sheets.createIndex({ "procedures.advised_at_facility_id": 1, "procedures.counselled_datetime": 1 },
  #                            { name: "procedure_counselled_date_wise_index" })
  # db.case_sheets.createIndex({ "ophthal_investigations.advised_at_facility_id": 1,
  #                              "ophthal_investigations.counselled_datetime": 1 },
  #                            { name: "ophthal_counselled_date_wise_index" })
  # db.case_sheets.createIndex({ "laboratory_investigations.advised_at_facility_id": 1,
  #                              "laboratory_investigations.advised_datetime": 1 },
  #                            { name: "laboratory_counselled_date_wise_index" })
  # db.case_sheets.createIndex({ "radiology_investigations.advised_by_id": 1})
  # db.case_sheets.createIndex({ "procedures.advised_by_id": 1})
  # db.case_sheets.createIndex({ "ophthal_investigations.advised_by_id": 1})
  # db.case_sheets.createIndex({ "laboratory_investigations.advised_by_id": 1})
  # db.case_sheets.createIndex({ "organisation_id": 1, "is_migrated": 1, "diagnoses.entered_datetime": 1})
  # db.case_sheets.createIndex({ "procedures.admission_id": 1})
  # counselled_by_id yet to be done
  # db.case_sheets.createIndex({ "diagnoses.entered_datetime": 1, "diagnoses.entered_from": 1, "organisation_id": 1})
end
