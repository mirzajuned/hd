class TpaInsurancePreAuthorizationForm
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :patient_name, type: String
  field :patient_contact_no, type: String
  field :toll_free_fax, type: String
  field :is_insured, type: Boolean
  field :patient_insurance_id, type: BSON::ObjectId
  field :insurance_name, type: String     # name of the insurance company
  field :tpa_name, type: String           # name of the third party
  field :tpa_contact_no, type: String     # contact no third party
  field :insurance_address, type: String
  field :tpa_address, type: String
  field :tpa_contact_person, type: String
  field :insurance_policy_no, type: String # policy no of patient insurance
  field :insurance_policy_expiry_date, type: Date
  field :current_insurance_policy_expiry, type: Date
  field :insurer, type: String            # personal or via company
  field :company_name, type: String       # In case insurer is company.
  field :employee_id, type: String        # In case insurer is company.
  field :insurance_status, type: String   # Waiting,Approved,Rejected
  field :comment, type: String
  field :patient_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :patient_contact_person, type: String
  field :patient_address, type: String
  field :admission_id, type: BSON::ObjectId
  field :tpa_contact_id, type: BSON::ObjectId
  field :insurance_contact_id, type: BSON::ObjectId
  field :tpa_insurance_workflow_id, type: BSON::ObjectId
  field :approved_amount, type: Integer
  field :bracket_amount, type: Integer
  field :clinical_findings, type: String
  field :current_company_name, type: String
  field :current_family_physician_name, type: String
  field :insurance_contact_no, type: String
  field :insurance_contact_person, type: String
  field :current_insurance_contact_no, type: String
  field :current_insurance_details, type: String
  field :current_insurance_policy_no, type: String
  field :current_insurance_sum_insured, type: String
  field :date_of_admission, type: Date
  field :date_of_first_consultation, type: Date
  field :date_of_injury, type: Date
  field :doctor_hospital_contact_no, type: String
  field :doctor_name, type: String
  field :doctor, type: BSON::ObjectId
  field :duration_of_present_ailment, type: String
  field :employee_id, type: String
  field :expected_days_stay, type: String
  field :expected_inv_diag_cost, type: String
  field :fir_no, type: String
  field :gender, type: String
  field :icd_code, type: String
  field :icd_pcs_code, type: String
  field :icu_charges, type: String
  field :inclusive_package_charges, type: String
  field :injury_occur_reason, type: String
  field :insured_card_id_no, type: String
  field :insurer, type: String
  field :investigation_medical_management_details, type: String
  field :reported_to_police, type: Boolean, default: false
  field :is_alcohal_comsumption, type: Boolean, default: false
  field :is_alcohal_test_conducted, type: Boolean, default: false
  field :is_currently_insured, type: Boolean, default: false
  field :day_room_nursing_patient_diet, type: String
  field :is_rta, type: Boolean, default: false
  field :lmp_date, type: Date
  field :medicine_consume_implants_cost, type: String
  field :nature_of_disease, type: String
  field :ot_charges, type: String
  field :other_treatment_details, type: String
  field :past_history_present_ailment, type: String
  field :patient_age, type: String
  field :patient_exact_age, type: String
  field :patient_contact_no, type: String
  field :professional_anesthetist_consultant_charges, type: String
  field :provisional_diagnosis, type: String
  field :room_type, type: String
  field :route_drug_administration, type: String
  field :surgical_name_surgery, type: String
  field :time_of_admission, type: Time
  field :maternity_g, type: Boolean, default: false
  field :maternity_p, type: Boolean, default: false
  field :maternity_l, type: Boolean, default: false
  field :maternity_a, type: Boolean, default: false
  field :medical_management, type: Boolean, default: false
  field :surgical_management, type: Boolean, default: false
  field :intensive_care, type: Boolean, default: false
  field :investigation, type: Boolean, default: false
  field :non_allopathic_treatment, type: Boolean, default: false
  field :hospitalization_type, type: String
  field :total_hospitalization_cost, type: String

  # field :heart_disease, type: Boolean, default: false
  # field :heart_disease_duration, type: String
  # field :heart_disease_duration_unit, type: String
  # field :hypertension, type: Boolean, default: false
  # field :hypertension_duration, type: String
  # field :hypertension_duration_unit, type: String
  # field :hyperlipidemias, type: Boolean, default: false
  # field :hyperlipidemias_duration, type: String
  # field :hyperlipidemias_duration_unit, type: String
  # field :osteoarthritis, type: Boolean, default: false
  # field :osteoarthritis_duration, type: String
  # field :osteoarthritis_duration_unit, type: String
  # field :asthma_copd_bronchitis, type: Boolean, default: false
  # field :asthma_copd_bronchitis_duration, type: String
  # field :asthma_copd_bronchitis_duration_unit, type: String
  # field :cancer, type: Boolean, default: false
  # field :cancer_duration, type: String
  # field :cancer_duration_unit, type: String
  # field :hiv_std_related_ailment, type: Boolean, default: false
  # field :hiv_std_related_ailment_duration, type: String
  # field :hiv_std_related_ailment_duration_unit, type: String
  # field :chronic_other_details, type: String

  field :diabetes, type: Boolean, default: false
  field :diabetes_duration, type: String
  field :diabetes_duration_unit, type: String

  field :hypertension, type: Boolean, default: false
  field :hypertension_duration, type: String
  field :hypertension_duration_unit, type: String

  field :alcoholism, type: Boolean, default: false
  field :alcoholism_duration, type: String
  field :alcoholism_duration_unit, type: String

  field :smoking_tobacco, type: Boolean, default: false
  field :smoking_tobacco_duration, type: String
  field :smoking_tobacco_duration_unit, type: String

  field :cardiac_disorder, type: Boolean, default: false
  field :cardiac_disorder_duration, type: String
  field :cardiac_disorder_duration_unit, type: String

  field :rheumatoid_arthritis, type: Boolean, default: false
  field :rheumatoid_arthritis_duration, type: String
  field :rheumatoid_arthritis_duration_unit, type: String

  field :steroid_intake, type: Boolean, default: false
  field :steroid_intake_duration, type: String
  field :steroid_intake_duration_unit, type: String

  field :drug_abuse, type: Boolean, default: false
  field :drug_abuse_duration, type: String
  field :drug_abuse_duration_unit, type: String

  field :hiv_aids, type: Boolean, default: false
  field :hiv_aids_duration, type: String
  field :hiv_aids_duration_unit, type: String

  field :cancer_tumor, type: Boolean, default: false
  field :cancer_tumor_duration, type: String
  field :cancer_tumor_duration_unit, type: String

  field :tuberculosis, type: Boolean, default: false
  field :tuberculosis_duration, type: String
  field :tuberculosis_duration_unit, type: String

  field :asthma, type: Boolean, default: false
  field :asthma_duration, type: String
  field :asthma_duration_unit, type: String

  field :cns_disorder_stroke, type: Boolean, default: false
  field :cns_disorder_stroke_duration, type: String
  field :cns_disorder_stroke_duration_unit, type: String

  field :hypothyroidism, type: Boolean, default: false
  field :hypothyroidism_duration, type: String
  field :hypothyroidism_duration_unit, type: String

  field :hyperthyroidism, type: Boolean, default: false
  field :hyperthyroidism_duration, type: String
  field :hyperthyroidism_duration_unit, type: String

  field :hepatitis_cirrhosis, type: Boolean, default: false
  field :hepatitis_cirrhosis_duration, type: String
  field :hepatitis_cirrhosis_duration_unit, type: String

  field :renal_disorder, type: Boolean, default: false
  field :renal_disorder_duration, type: String
  field :renal_disorder_duration_unit, type: String

  field :acidity, type: Boolean, default: false
  field :acidity_duration, type: String
  field :acidity_duration_unit, type: String

  field :on_insulin, type: Boolean, default: false
  field :on_insulin_duration, type: String
  field :on_insulin_duration_unit, type: String

  field :on_aspirin_blood_thinners, type: Boolean, default: false
  field :on_aspirin_blood_thinners_duration, type: String
  field :on_aspirin_blood_thinners_duration_unit, type: String

  field :consanguinity, type: Boolean, default: false
  field :consanguinity_duration, type: String
  field :consanguinity_duration_unit, type: String

  field :thyroid_disorder, type: Boolean, default: false
  field :thyroid_disorder_duration, type: String
  field :thyroid_disorder_duration_unit, type: String

  field :chewing_tobacco, type: Boolean, default: false
  field :chewing_tobacco_duration, type: String
  field :chewing_tobacco_duration_unit, type: String

  # Documents For Cashless
  field :document_tpa_form, type: Boolean
  field :document_insurancecard, type: Boolean
  field :document_passport, type: Boolean
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

  belongs_to :patient
  # belongs_to :admission
  # embeds_many :insurance_documents
  # accepts_nested_attributes_for :insurance_documents, allow_destroy: true
end

# indexes on this model's fields

# db.tpa_insurance_pre_authorization_forms.createIndex({ tpa_insurance_workflow_id: 1 })
