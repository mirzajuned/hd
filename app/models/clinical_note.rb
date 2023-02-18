class ClinicalNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :template_type, type: String, default: "Clinical Note"
  field :template_id, type: String, default: "32485007"
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
  field :expected_management, type: String
  field :note_created_at, type: DateTime, default: Time.current
  field :expected_discharge_date, type: Date
  field :admissionreason, type: String

  field :injury_complaint_date, type: String
  field :first_opd_visit, type: String
  field :ipd_payment_type, type: String
  field :ipd_billing_category, type: String
  field :medico_legal_details, type: String
  field :selected_opdrecord_id, type: String
  field :investigations, type: String
  field :procedure_planned, type: String

  field :airway_assesment_abnormal, type: String
  field :breathing_assesment_abnormal, type: String
  field :pulse_assesment_abnormal, type: String
  field :cns_temperature_abnormal, type: String
  field :cns_orientation_abnormal, type: String
  field :cns_emotinal_status_abnormal, type: String
  field :cns_memory_intact_abnormal, type: String
  field :cns_speech_status_abnormal, type: String
  field :resp_breath_sounds_abnormal, type: String
  field :bp_assesment_abnormal, type: String
  field :cvs_palpable_pulses_intact_abnormal, type: String
  field :resp_nail_bed_color_abnormal, type: String
  field :resp_air_entry, type: String
  field :cvs_heart_sounds_status_abnormal, type: String
  field :cvs_peripheral_edema, type: String
  field :cvs_calf_tenderness, type: String
  field :gut_urine_output_abnormal, type: String
  field :gut_bladder_habits_abnormal, type: String
  field :git_abdomen, type: String
  field :git_bowel_movements_abnormal, type: String
  field :ms_extreme_motion_abnormal, type: String
  field :ms_sensation_abnormal, type: String
  field :skin_color_abnormal, type: String
  field :skin_integrity_abnormal, type: String

  field :expected_length_of_stay, type: String
  field :insurance_name, type: String
  field :tpa_name, type: String
  field :govt_scheme, type: String
  field :reason_for_complaints, type: String
  field :preexisting_problems, type: String
  field :provisional_diagnosis, type: String
  field :general_clubbing, type: String
  field :general_edema, type: String

  field :department_id, type: String

  embeds_many :record_histories
  embedded_in :ipd_record, class_name: "::Inpatient::IpdRecord"

  after_save {
    self.update_admission
    self.update_admission_note
  }

  def checkboxes_checked(checked)
    checked&.split(',')
  end

  def update_admission
    @admission = Admission.find_by(id: self.admission_id)
    if @admission
      @admission.update_attributes(admissionreason: self.admissionreason, dischargedate: self.expected_discharge_date)
    end
  end

  def update_admission_note
    @admission_note = Inpatient::IpdRecord::AdmissionNote.find_by(admission_id: self.admission_id)
    if @admission_note
      @admission_note.update_attributes(expected_stay: self.expected_stay, payment_type: self.ipd_payment_type, medico_legal_case: self.medico_legal_case, medico_legal_details: self.medico_legal_details)
    end
  end
end
