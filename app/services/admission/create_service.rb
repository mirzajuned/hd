class Admission::CreateService
  def self.call(params, current_user, patient, _integration = false)
    admissiontime = (params[:admissiontime].present?) ? params[:admissiontime] : Time.current
    if params[:dischargedate].present? && params[:dischargetime].present?
      admissiontime = Time.zone.parse(admissiontime)
      dischargetime = Time.zone.parse(params[:dischargetime])
      params[:dischargedate] = admissiontime if admissiontime > dischargetime
      params[:dischargetime] = admissiontime if admissiontime > dischargetime
    end

    params[:created_from] = 'Integration' if _integration
    params[:patient_id] = patient.id.to_s
    params[:bkp_display_id] = CommonHelper.get_ipd_record_identifier(current_user)
    # params[:patient_insurance_id] = params[:current_insurance_id]

    params[:insurance_status] = if params[:is_insured] == 'No'
                                  'Not Insured'
                                else
                                  'Waiting'
                                end

    # setting insurance_fields if selected from patient_existing_insurances
    if params[:patient_insurance_id].present?
      params[:insurance_contact_id] = params[:hidden_insurance_contact_id]
      params[:insurance_name] = params[:hidden_insurance_name]
      params[:insurance_contact_no] = params[:hidden_insurance_contact_no]
      params[:insurance_contact_person] = params[:hidden_insurance_contact_person]
      params[:insurance_address] = params[:hidden_insurance_address]
      params[:insurance_policy_no] = params[:hidden_insurance_policy_no]
      params[:insurance_policy_expiry_date] = params[:hidden_insurance_policy_expiry_date]
    end

    admission = Admission.new(admission_params(params))
    if admission.save
      display_id = SequenceManagers::GenerateSequenceService.call('admission', admission.id.to_s, { organisation_id: admission.organisation_id.to_s, facility_id: admission.facility_id.to_s, region_id: admission.facility.try(:region_master_id).to_s, department_id: admission.department_id })
      admission.update(display_id: display_id)
    end

    admission
  end

  private

  def self.admission_params(params)
    params.permit(
      :admissionreason, :admission_type, :managementplan, :admissiondate, :admissiontime, :dischargedate,
      :patient_arrived, :insurance_status, :facility_id, :specialty_id, :doctor, :doctor_1, :doctor_2,
      :doctor_3, :anesthesia, :ward_id, :room_id, :bed_id, :daycare,
      :patient_id, :user_id, :organisation_id, :department_id, :dischargetime, :display_id, :case_sheet_id,
      :insurance_selected_id, :admission_hospitalisation_type, :is_insured, :admission_hospitalization_type,
      :patient_insurance_id, :insurance_name, :insurance_id, :insurance_address, :insurance_email, :created_from,
      :insurance_contact_no, :insurance_contact_person, :tpa_name, :tpa_contact_id, :tpa_contact_no,
      :tpa_contact_person, :tpa_address, :tpa_email, :patient_contact_person, :insurance_policy_no,
      :insurance_policy_expiry_date, :insurance_type, :company_name, :employee_id, :comment, :patient_id,
      :insurance_status, :bracket_amount, :document_passport, :document_aadharcard, :document_electioncard,
      :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form,
      :sum_insured, :insurance_comments, :insurance_contact_id, :document_passport, :document_aadharcard,
      :document_electioncard, :document_insurancecard, :document_government_id, :document_vss, :document_employeecard,
      :document_drivinglicense, :document_others, :document_tpa_form, :document_patient_cancelled_cheque,
      :patient_visit_category, :patient_category, :reporting_date, :reporting_time,
      admission_milestones_attributes: [:id, :label, :user_id, :position]
    )
  end
end
