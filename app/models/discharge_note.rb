class DischargeNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :template_type, type: String, default: "Discharge Note"
  field :template_id, type: String, default: "373942005"
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :admission_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :doctor_id, type: BSON::ObjectId
  field :department, type: String
  field :specalityname, type: String
  field :specalityid, type: String
  field :encountertype, type: String, default: "IPD"
  field :encountertypeid, type: String, default: "440654001"
  field :note_created_at, type: Time, default: Time.current
  field :medicationsets, type: Array
  field :followup_doctor_id, type: String
  field :followup_facility, type: String
  field :bookappointment, type: String
  field :treatment_type, type: String
  field :check_all, type: String
  field :discharge_intimation, type: String
  field :band_removed, type: String
  field :intracath_removed, type: String
  field :discharge_summary_given, type: String
  field :correct_dose_explained, type: String
  field :wound_dressing_needs, type: String
  field :process_of_followup_explained, type: String
  field :pending_reports_given, type: String
  field :emergency_contact_explained, type: String
  field :followup_appointment_id, type: String
  field :investigation_notes, type: String
  field :print_procedure, type: Boolean, default: true
  field :print_investigation, type: Boolean, default: true
  field :print_implant, type: Boolean, default: true
  embeds_many :record_histories
  embeds_many :treatmentmedication, class_name: "::MedicationRecord" # medications
  embedded_in :ipd_record, class_name: "::Inpatient::IpdRecord"
  embeds_many :generic_names, class_name: '::Inventory::Item::GenericName'

  accepts_nested_attributes_for :treatmentmedication, class_name: "::MedicationRecord", allow_destroy: true, reject_if: proc { |attributes| attributes['medicinename'].empty? } # medications
  accepts_nested_attributes_for :record_histories, class_name: "::RecordHistory"
  accepts_nested_attributes_for :generic_names, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true

  field :appointment_type_id, type: String
  field :appointment_category_id, type: String
  field :store_name, type: String
  field :store_id, type: BSON::ObjectId
  # after_save {
  #   self.update_discharge_details
  # }

  def update_discharge_details
    @admission = Admission.find_by(id: self.admission_id)
    if @admission
      @admission.update(dischargedate: self.discharge_date, dischargetime: self.discharge_time)
    end
  end

  def checkboxes_checked(checked)
    checked&.split(',')
  end
end
