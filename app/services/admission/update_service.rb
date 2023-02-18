class Admission::UpdateService
  def self.call(params, current_user, admission, _integration = false)
    @admission = admission
    if params[:dischargedate].present? && params[:dischargetime].present?
      admissiontime = Time.zone.parse(params[:admissiontime])
      dischargetime = Time.zone.parse(params[:dischargetime])
      params[:dischargedate] = params[:admissiondate] if admissiontime > dischargetime
      params[:dischargetime] = params[:admissiontime] if admissiontime > dischargetime
    end

    params[:patient_id] = @admission.patient_id.to_s

    past_facility_id = @admission.facility_id
    past_specialty_id = @admission.specialty_id
    past_admissiondate = @admission.admissiondate

    if @admission.update_attributes(admission_params(params))
      update_ipd_record_specialty
      # respond_to do |format|
      #   format.js { render 'close' }
      # end

      Analytics::Admission::UpdateService.update_admission_created_count(@admission.id, past_facility_id, past_admissiondate, past_specialty_id)
      # Report code commented because outdated
      # Reports::Ipd::Admissions.call(@admission)
      Patients::Summary::TimelineWorker.call(event_name: 'IPD_ADMISSION', sub_event_name: 'EDITED', admission_id: @admission.id, user_id: current_user.id, user_name: current_user.fullname)

    end
    @admission
  end

  private

  def self.admission_params(params)
    params.permit(
      :admissionreason, :admission_type, :managementplan, :admissiondate, :admissiontime, :dischargedate,
      :patient_arrived, :insurance_status, :facility_id, :specialty_id, :doctor, :ward_id, :room_id, :bed_id, :daycare,
      :patient_id, :user_id, :organisation_id, :department_id, :dischargetime, :display_id, :case_sheet_id,
      :insurance_selected_id, :admission_hospitalisation_type, :is_insured, :admission_hospitalization_type,
      :patient_insurance_id, :insurance_name, :insurance_id, :insurance_address, :insurance_email,
      :insurance_contact_no, :insurance_contact_person, :tpa_name, :tpa_contact_id, :tpa_contact_no,
      :tpa_contact_person, :tpa_address, :tpa_email, :patient_contact_person, :insurance_policy_no,
      :insurance_policy_expiry_date, :insurance_type, :company_name, :employee_id, :comment, :patient_id,
      :insurance_status, :bracket_amount, :document_passport, :document_aadharcard, :document_electioncard,
      :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form,
      :sum_insured, :insurance_comments, :insurance_contact_id, :document_passport, :document_aadharcard,
      :document_electioncard, :document_insurancecard, :document_government_id, :document_vss, :document_employeecard,
      :document_drivinglicense, :document_others, :document_tpa_form, :document_patient_cancelled_cheque,
      admission_milestones_attributes: [:id, :label, :user_id, :position]
    )
  end

  def self.update_ipd_record_specialty
    ipd_record = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
    if ipd_record
      ipd_record.update(specialty_id: @admission.specialty_id) if ipd_record.specialty_id != @admission.specialty_id
    end
  end
end
