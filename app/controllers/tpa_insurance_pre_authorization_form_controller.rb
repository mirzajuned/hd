class TpaInsurancePreAuthorizationFormController < ApplicationController
  before_action :set_user_facility
  before_action :tpa_form_initial_params, only: [:new, :edit]

  def new
    # not needed, because data gets filled by tpa_details_form method below
  end

  def create
    # not needed, because data gets filled by tpa_details_form method below
  end

  def edit
    @insurance_details = TpaInsurancePreAuthorizationForm.find_by(id: params[:id])

    respond_to do |format|
      format.js {}
    end
  end

  def update
    @insurance_details = TpaInsurancePreAuthorizationForm.find_by(id: params[:id])
    @insurance_details.update_attributes(insurance_form_params)

    respond_to do |format|
      format.js { render 'update' }
    end
  end

  def print_tpa_form
    @insurance_details = TpaInsurancePreAuthorizationForm.find_by(id: params[:id])
    @patient = Patient.find_by(id: @insurance_details.patient_id)

    setting_service = PrintSettingService.new(@current_facility.id, @insurance_details.doctor.to_s, "OPD")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    filename = "PreAuth_form_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"

    respond_to do |format|
      format.pdf { render :template => "tpa_insurance_pre_authorization_form/print_tpa_form", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 0 }, :footer => { :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 8, right: @print_settings[0]['right_margin'].to_f * 10, :top => 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  # for saving important fields for main pre - auth form
  def tpa_details_form
    @tpa_workflow = TpaInsuranceWorkflow.find_by(id: params[:tpa_workflow_id])
    @patient = Patient.find_by(id: params[:patient_id])

    # case when admission is linked
    if @tpa_workflow.admission_id.present?
      @admission = Admission.find_by(id: @tpa_workflow.admission_id)
    else
      # case when unlinked admission is present
      @admission = Admission.find_by(id: params[:admission_id])
    end
    get_admission_form_values if @admission

    respond_to do |format|
      format.js { render 'tpa_insurance_pre_authorization_form/tpa_details_form' }
    end
  end

  def tpa_details_form_save
    params[:tpa_data] = params[:admission]
    # setting insurance_fields, if selected from patient_existing_insurances
    if params[:tpa_data][:patient_insurance_id].present?
      params[:tpa_data][:insurance_contact_id] = params[:tpa_data][:hidden_insurance_contact_id]
      params[:tpa_data][:insurance_name] = params[:tpa_data][:hidden_insurance_name]
      params[:tpa_data][:insurance_contact_no] = params[:tpa_data][:hidden_insurance_contact_no]
      params[:tpa_data][:insurance_contact_person] = params[:tpa_data][:hidden_insurance_contact_person]
      params[:tpa_data][:insurance_address] = params[:tpa_data][:hidden_insurance_address]
      params[:tpa_data][:insurance_policy_no] = params[:tpa_data][:hidden_insurance_policy_no]
      params[:tpa_data][:insurance_policy_expiry_date] = params[:tpa_data][:hidden_insurance_policy_expiry_date]
    end

    @admission = Admission.find_by(id: params[:tpa_data][:admission_id])
    @tpa_workflow = TpaInsuranceWorkflow.find_by(id: params[:tpa_data][:tpa_insurance_workflow_id])
    @tpa_workflow.update(admissions_linked: [@admission.try(:id)]) if @tpa_workflow.admissions_linked.count == 0

    @insurance_form = TpaInsurancePreAuthorizationForm.find_by(tpa_insurance_workflow_id: @tpa_workflow.id)
    admissiontime, dischargetime = Time.zone.parse(params[:tpa_data][:admissiontime]), Time.zone.parse(params[:tpa_data][:dischargetime])
    params[:tpa_data][:dischargedate] = params[:tpa_data][:admissiondate] if admissiontime > dischargetime
    params[:tpa_data][:dischargetime] = params[:tpa_data][:admissiontime] if admissiontime > dischargetime

    unless @insurance_form
      @insurance_form = TpaInsurancePreAuthorizationForm.new(insurance_form_params)
      @insurance_form.save
    else
      @insurance_form.update_attributes(insurance_form_params)
    end

    # creating new Patient Insurance record
    unless params[:tpa_data][:patient_insurance_id].present?
      if params[:tpa_data][:is_insured] == "Yes"
        @insurance = PatientInsurance.new(patient_insurance_params)
        if @insurance.save
          @admission.update(patient_insurance_id: @insurance.id)

          # used intentionally, without this, id is not getting saved
          params[:tpa_data][:patient_insurance_id] = @insurance.id
        end
      end
    end
    @admission.update(admission_params)
    update_tpa_opd_workflow

    respond_to do |format|
      format.js { render 'tpa/insurance/update_tpa_workflow' }
    end
  end

  private

  def get_admission_form_values
    @current_date = @admission.admissiondate
    @min_date = @current_date
    @current_time = @admission.admissiontime
    @discharge_date = @admission.dischargedate
    @discharge_time = @admission.dischargetime
    @selected_facility = @admission.facility_id
    @selected_doctor = @admission.doctor
    @current_insurances = PatientInsurance.where(patient_id: @patient.id)

    facility = Facility.find_by(id: @selected_facility)

    final_specialties = facility.specialty_ids & current_user.specialty_ids
    final_specialties = facility.specialty_ids if !final_specialties.present? # finding final_specialties of selected facility if no specialty present. for eg -> TPA case
    @available_specialties = Specialty.where(:id.in => final_specialties).pluck(:name, :id).sort
    @selected_specialty = @admission.specialty_id || params[:specialty_id] || if @available_specialties.present? then @available_specialties.first[1] end || ""
    @available_doctors = User.where(facility_ids: @selected_facility, role_ids: 158965000, specialty_ids: @selected_specialty, is_active: true).pluck("fullname", "id")

    get_insurance_tpa_contacts
  end

  def set_user_facility
    @current_user = current_user
    @current_facility = current_facility
  end

  def tpa_form_initial_params
    if params[:data_class] == 'AdmissionListView'
      admission_id = AdmissionListView.find_by(id: params[:workflow_id]).try(:admission_id)
      @workflow = TpaInsuranceWorkflow.find_by(admission_id: admission_id.to_s)
    elsif params[:data_class] != 'TpaInsuranceWorkflow'
      appointment_id = OpdClinicalWorkflow.find_by(id: params[:workflow_id]).try(:appointment_id)
      @workflow = TpaInsuranceWorkflow.find_by(appointment_id: appointment_id.to_s)
    else
      @workflow = TpaInsuranceWorkflow.find_by(id: BSON::ObjectId(params[:workflow_id]))
    end

    @patient = Patient.find_by(id: @workflow.patient_id)
    @admission = Admission.find_by(id: @workflow.admission_id) if @workflow.admission_id.present?
    @doctors = User.where(:facility_ids.in => [current_facility.id], role_ids: 158965000, is_active: true).sort(fullname: :asc)

    get_insurance_tpa_contacts
  end

  def insurance_form_params
    params.require(:tpa_data).permit(:patient_id, :patient_contact_person, :facility_id, :organisation_id, :is_insured, :admission_id, :tpa_name, :tpa_contact_id, :tpa_contact_no, :tpa_address, :tpa_contact_person, :tpa_email, :insurance_contact_no, :insurance_contact_id, :insurance_name, :insurance_address, :insurance_contact_person, :insurance_email, :tpa_insurance_workflow_id, :insurance_policy_no, :insurance_policy_expiry_date, :toll_free_fax, :patient_name, :patient_contact_no, :gender, :patient_age, :patient_exact_age, :patient_contact_person, :patient_address, :insured_card_id_no, :employee_id, :is_currently_insured, :current_company_name, :current_insurance_details, :current_insurance_policy_no, :current_insurance_policy_expiry, :current_insurance_sum_insured, :current_family_physician_name, :current_insurance_contact_no, :date_of_admission, :time_of_admission, :expected_days_stay, :room_type, :day_room_nursing_patient_diet, :expected_inv_diag_cost, :icu_charges, :ot_charges, :professional_anesthetist_consultant_charges, :medicine_consume_implants_cost, :inclusive_package_charges, :diabetes, :diabetes_duration, :diabetes_duration_unit, :hypertension, :hypertension_duration, :hypertension_duration_unit, :alcoholism, :alcoholism_duration, :alcoholism_duration_unit, :smoking_tobacco, :smoking_tobacco_duration, :smoking_tobacco_duration_unit, :cardiac_disorder, :cardiac_disorder_duration, :cardiac_disorder_duration_unit, :rheumatoid_arthritis, :rheumatoid_arthritis_duration, :rheumatoid_arthritis_duration_unit, :steroid_intake, :steroid_intake_duration, :steroid_intake_duration_unit, :drug_abuse, :drug_abuse_duration, :drug_abuse_duration_unit, :hiv_aids, :hiv_aids_duration, :hiv_aids_duration_unit, :cancer_tumor, :cancer_tumor_duration, :cancer_tumor_duration_unit, :tuberculosis, :tuberculosis_duration, :tuberculosis_duration_unit, :asthma, :asthma_duration, :asthma_duration_unit, :cns_disorder_stroke, :cns_disorder_stroke_duration, :cns_disorder_stroke_duration_unit, :hypothyroidism, :hypothyroidism_duration, :hypothyroidism_duration_unit, :hyperthyroidism, :hyperthyroidism_duration, :hyperthyroidism_duration_unit, :hepatitis_cirrhosis, :hepatitis_cirrhosis_duration, :hepatitis_cirrhosis_duration_unit, :renal_disorder, :renal_disorder_duration, :renal_disorder_duration_unit, :acidity, :acidity_duration, :acidity_duration_unit, :on_insulin, :on_insulin_duration, :on_insulin_duration_unit, :on_aspirin_blood_thinners, :on_aspirin_blood_thinners_duration, :on_aspirin_blood_thinners_duration_unit, :consanguinity, :consanguinity_duration, :consanguinity_duration_unit, :thyroid_disorder, :thyroid_disorder_duration, :thyroid_disorder_duration_unit, :doctor_id, :doctor_name, :doctor_hospital_contact_no, :nature_of_disease, :clinical_findings, :duration_of_present_ailment, :date_of_first_consultation, :past_history_present_ailment, :provisional_diagnosis, :icd_code, :investigation_medical_management_details, :route_drug_administration, :surgical_name_surgery, :icd_pcs_code, :other_treatment_details, :injury_occur_reason, :is_rta, :date_of_injury, :reported_to_police, :fir_no, :is_alcohal_comsumption, :is_alcohal_test_conducted, :lmp_date, :maternity_g, :maternity_p, :maternity_l, :maternity_a, :medical_management, :surgical_management, :intensive_care, :investigation, :non_allopathic_treatment, :admissionreason, :managementplan, :admissiondate, :admissiontime, :dischargedate, :patient_arrived, :insurance_status, :doctor, :user_id, :department_id, :dischargetime, :display_id, :case_sheet_id, :insurance_selected_id, :admission_hospitalisation_type, :admission_hospitalization_type, :patient_insurance_id, :insurance_id, :insurance_type, :company_name, :comment, :bracket_amount, :document_passport, :document_aadharcard, :document_electioncard, :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form, :document_patient_cancelled_cheque, :sum_insured, :insurance_comments, :chronic_other_details, :total_hospitalization_cost, :admissions_linked => [])
  end

  def admission_params
    params.require(:tpa_data).permit(:admissionreason, :patient_contact_person, :managementplan, :admissiondate, :admissiontime, :dischargedate, :patient_arrived, :insurance_status, :facility_id, :doctor, :ward_id, :room_id, :bed_id, :daycare, :patient_id, :user_id, :organisation_id, :department_id, :dischargetime, :display_id, :case_sheet_id, :insurance_selected_id, :admission_hospitalisation_type, :is_insured, :admission_hospitalization_type, :patient_insurance_id, :insurance_name, :insurance_id, :insurance_address, :insurance_email, :insurance_contact_no, :insurance_contact_id, :insurance_contact_person, :tpa_name, :tpa_contact_id, :tpa_contact_no, :tpa_contact_person, :tpa_address, :tpa_email, :insurance_policy_no, :insurance_policy_expiry_date, :insurance_type, :company_name, :employee_id, :comment, :patient_id, :insurance_status, :bracket_amount, :document_passport, :document_aadharcard, :document_electioncard, :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form, :document_patient_cancelled_cheque, :sum_insured, :insurance_comments)
  end

  def patient_insurance_params
    params.require(:tpa_data).permit(:patient_id, :organisation_id, :facility_id, :insurance_name, :insurance_address, :insurance_email, :insurance_contact_no, :insurance_contact_person, :insurance_policy_no, :policy_issued_date, :insurance_policy_expiry_date, :admission_id, :insurance_contact_id)
  end

  def update_tpa_opd_workflow
    @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)
    @tpa_workflow.update(admission_id: @admission.id, tpa_admission_date: @admission_list_view.try(:admission_date), tpa_admission_doctor: @admission_list_view.try(:admitting_doctor))
    @opd_workflow = OpdClinicalWorkflow.find_by(appointment_id: @tpa_workflow.appointment_id.to_s)
    if @opd_workflow.present?
      @opd_workflow.update_attributes(tpa_admission_date: @admission_list_view.try(:admission_date), tpa_admission_doctor: @admission_list_view.try(:admitting_doctor), tpa_admission_id: @admission.id)
    end
  end

  def get_insurance_tpa_contacts
    @current_user = current_user
    @contact_groups = ContactGroup.where(organisation_id: @current_user.organisation_id, contact_group_type: 'tpa')
    @tpa_contact = @contact_groups.find_by(name: 'TPA')
    @insurance_contact = @contact_groups.find_by(name: 'Insurance')

    @contacts = Contact.where(is_deleted: false, organisation_id: @current_user.organisation_id)
    @tpa_contacts = @contacts.where(contact_group_id: @tpa_contact.try(:id))
    @insurance_contacts = @contacts.where(contact_group_id: @insurance_contact.try(:id))
  end
end
