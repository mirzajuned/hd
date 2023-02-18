class Inpatient::Insurance::Tpa
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :patient_name, type: String
  field :patient_contact_no, type: String
  field :toll_free_fax, type: String
  field :is_insured, type: Boolean
  field :insurance_name, type: String     # name of the insurance company
  field :tpa_name, type: String           # name of the third party
  field :tpa_contact_no, type: String     # contact no third party
  field :insurance_address, type: String
  field :tpa_address, type: String
  field :policy_no, type: String          # policy no of patient insurance
  field :insurer, type: String            # personal or via company
  field :company_name, type: String       # In case insurer is company.
  field :employee_id, type: String        # In case insurer is company.
  field :insurance_status, type: String   # Waiting,Approved,Rejected
  field :comment, type: String
  field :patient_id, type: BSON::ObjectId
  field :tpa_contact_id, type: BSON::ObjectId
  field :approved_amount, type: Integer
  field :bracket_amount, type: Integer
  field :clinical_findings, type: String
  field :current_company_name, type: String
  field :current_family_physician_name, type: String
  field :insurance_contact_no, type: String
  field :current_insurance_contact_no, type: String
  field :current_insurance_details, type: String
  field :current_insurance_policy_no, type: String
  field :current_insurance_sum_insured, type: String
  field :date_of_admission, type: String
  field :date_of_first_consultation, type: String
  field :date_of_injury, type: String
  field :doctor_hospital_contact_no, type: String
  field :doctor_name, type: String
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
  field :is_rta, type: Boolean, default: false
  field :lmp_date, type: String
  field :medicine_consume_implants_cost, type: String
  field :nature_of_disease, type: String
  field :ot_charges, type: String
  field :other_treatment_details, type: String
  field :past_history_present_ailment, type: String
  field :patient_age, type: String
  field :patient_contact_no, type: String
  field :professional_anesthetist_consultant_charges, type: String
  field :provisional_diagnosis, type: String
  field :room_type, type: String
  field :route_drug_administration, type: String
  field :surgical_name_surgery, type: String
  field :time_of_admission, type: String
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

  # diseases durations
  field :diabetes, type: Boolean, default: false
  field :diabetes_month_duration, type: String
  field :diabetes_year_duration, type: String
  field :heart_disease, type: Boolean, default: false
  field :heart_disease_month_duration, type: String
  field :heart_disease_year_duration, type: String
  field :hypertension, type: Boolean, default: false
  field :hypertension_month_duration, type: String
  field :hypertension_year_duration, type: String
  field :hyperlipidemias, type: Boolean, default: false
  field :hyperlipidemias_month_duration, type: String
  field :hyperlipidemias_year_duration, type: String
  field :osteoarthritis, type: Boolean, default: false
  field :osteoarthritis_month_duration, type: String
  field :osteoarthritis_year_duration, type: String
  field :asthma_copd_bronchitis, type: Boolean, default: false
  field :asthma_copd_bronchitis_month_duration, type: String
  field :asthma_copd_bronchitis_year_duration, type: String
  field :cancer, type: Boolean, default: false
  field :cancer_month_duration, type: String
  field :cancer_year_duration, type: String
  field :alcohal_or_drug_abuse, type: Boolean, default: false
  field :alcohal_or_drug_abuse_month_duration, type: String
  field :alcohal_or_drug_abuse_year_duration, type: String
  field :hiv_std_related_ailment, type: Boolean, default: false
  field :hiv_std_related_ailment_month_duration, type: String
  field :hiv_std_related_ailment_year_duration, type: String

  # Documents For Cashless
  field :document_passport, type: Boolean
  field :document_government_id, type: Boolean
  field :document_insurancecard, type: Boolean
  field :document_employeecard, type: Boolean
  field :document_others, type: Boolean
  # India
  field :document_aadharcard, type: Boolean
  field :document_electioncard, type: Boolean
  field :document_drivinglicense, type: Boolean
  field :document_tpa_form, type: Boolean
  # Vietnam
  field :document_vss, type: Boolean

  belongs_to :patient
  belongs_to :admission
  # embeds_many :insurance_documents
  # accepts_nested_attributes_for :insurance_documents, allow_destroy: true
end
