class OtChecklist
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :admission_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId
  field :specalityid, type: String
  field :specalityname, type: String
  field :template_type, type: String, default: "otchecklist"
  field :template_id, type: String, default: "111111111"
  field :otchecklist_created_at, type: Time, default: Time.current

  # patient_confirmed
  field :correct_patient, type: Boolean
  field :correct_identity, type: Boolean
  field :site, type: Boolean
  field :correct_procedure, type: Boolean
  field :before_induction_valid_consent, type: Boolean
  # end

  # site marked
  field :site_marked, type: Boolean
  field :id_band_by_patient, type: Boolean
  # end

  # history_and physical condition
  field :history_physical_condition, type: Boolean
  # end

  # presurgical Assessment
  field :pre_surgical_assessemt, type: Boolean
  field :pupils_dilated, type: Boolean
  field :preoperative_medication, type: Boolean
  field :vital_monitored, type: Boolean
  field :surgical_antibiotic, type: Boolean
  field :iol_power_check, type: Boolean
  field :procedure_explained, type: Boolean
  field :bill_payment, type: Boolean
  # end

  # pre- anaesthesia assessment_complete
  field :pre_anaesthesia_complete, type: Boolean
  field :any_significant_systemic_ailments_noted, type: Boolean
  field :any_drug_allergy_noted, type: Boolean
  field :anaesthesia_safety_check, type: Boolean
  # end

  # airway
  field :difficult_airway, type: Boolean
  field :not_applicable, type: Boolean
  field :equipment_assessment_available, type: Boolean
  # end

  # History and anticoagulants
  field :history_and_anticoagulants, type: Boolean
  field :continued, type: Boolean
  field :stopped_as_instructed, type: Boolean
  # end

  # lidocaine test dose
  field :lidocaine_test_dose, type: String
  field :dose_given_by, type: String
  field :dose_checked_by, type: String

  field :anesthesia_machine, type: Boolean
  field :manitol, type: Boolean
  field :tourniquet_drills_suction, type: Boolean
  field :implants_checked, type: Boolean

  field :confirm_team_listed, type: Boolean
  # surgon
  field :surgeon_nurse_orally_confirm, type: Boolean
  field :antibiotic_prophylaxis_given, type: Boolean
  field :mitomycin_c_anti_neo_plastic, type: Boolean
  field :implant_style_power, type: Boolean
  field :devices, type: Boolean
  field :tissue, type: Boolean
  field :dyes, type: Boolean
  # end

  # surgeon anaesthesia
  field :surgeon_anaesthesia_provider_and_nurse_orally_confirmed, type: Boolean
  field :patient_checked, type: Boolean
  field :site_checked_and_marked, type: Boolean
  field :procedure_checked, type: Boolean
  # end

  # Anticipated Creatical Events
  field :surgeon_review, type: Boolean
  field :critical_and_unexpected, type: Boolean
  field :reviewed, type: Boolean
  field :non_anticipated, type: Boolean
  field :operative_duration, type: Boolean
  field :anaesthesia_provided_review, type: Boolean
  field :any_patient_specific_concerns, type: Boolean
  field :nursing_team_reviews, type: Boolean
  field :sterility, type: Boolean
  field :equipment_issue, type: Boolean
  field :concerns, type: Boolean
  # end

  # Time out
  field :nurse_orally_confirm_with_team, type: Boolean
  field :procedure_recorded, type: Boolean
  field :equipment_issue_addressed, type: Boolean
  field :surgeon_anaesthesia_provider_and_nurse, type: Boolean
  field :recovery_management_reviewed, type: Boolean

  field :valid_consent, type: String
  field :imaging_checked, type: String
  field :xray_safety_check, type: String
  field :patient_allergy, type: String
  field :pre_op_iodine, type: String
  field :otchecklist_comments, type: String

  embeds_many :record_histories
  accepts_nested_attributes_for :record_histories, class_name: "::RecordHistory"

  def checkboxes_checked(checked)
    checked&.split(',')
  end
end
