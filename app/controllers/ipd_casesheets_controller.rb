class IpdCasesheetsController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  before_action :find_ipdrecord_for_write, :find_admission, :find_patient, only: [:update]
  before_action :find_ipdrecord, :find_admission, :find_patient, :find_patient_details, :find_templatetype, :find_tpa, :admission_note_form_params, only: [:edit]

  def edit
    @current_user = current_user
    @organisation = @current_user.organisation
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@ipdrecord.specialty_id)

    case @template_type
    when "admissionnote"
      get_admission_note_params
      render 'edit'
    when "clinicalnotenew"
      # redirect_to eval("new_inpatient_ipd_record_clinical_note_#{@speciality_folder_name}_note_path(admission_id: '#{@ipdrecord.admission_id}',:action => 'new')")
      redirect_to controller: "inpatient/ipd_record/clinical_note/#{@speciality_folder_name}_notes", action: 'new', admission_id: @ipdrecord.admission_id
    when "clinicalnoteedit"
      # redirect_to eval("edit_inpatient_ipd_record_clinical_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id,admission_id: '#{@ipdrecord.admission_id}',:action => 'edit')")
      redirect_to controller: "inpatient/ipd_record/clinical_note/#{@speciality_folder_name}_notes", action: 'edit', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id
    when "clinicalnoteshow"
      # redirect_to eval("inpatient_ipd_record_clinical_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id, admission_id: '#{@ipdrecord.admission_id}',:action => 'show')")
      redirect_to controller: "inpatient/ipd_record/clinical_note/#{@speciality_folder_name}_notes", action: 'show', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id
    when "operativenotenew"
      # redirect_to eval("new_inpatient_ipd_record_operative_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id,admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'new')")
      redirect_to controller: "inpatient/ipd_record/operative_note/#{@speciality_folder_name}_notes", action: 'new', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id.to_s
    when "operativenoteedit"
      # redirect_to eval("edit_inpatient_ipd_record_operative_note_#{@speciality_folder_name}_note_path(id: '#{params[:id]}',admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'new')")
      redirect_to controller: "inpatient/ipd_record/operative_note/#{@speciality_folder_name}_notes", action: 'new', id: params[:id], admission_id: @ipdrecord.admission_id.to_s
    when "dischargenotenew"
      # redirect_to eval("new_inpatient_ipd_record_discharge_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id,admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'new')")
      redirect_to controller: "inpatient/ipd_record/discharge_note/#{@speciality_folder_name}_notes", action: 'new', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id.to_s
    when "dischargenoteedit"
      # redirect_to eval("edit_inpatient_ipd_record_discharge_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id,admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'edit')")
      redirect_to controller: "inpatient/ipd_record/discharge_note/#{@speciality_folder_name}_notes", action: 'edit', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id.to_s
    when "dischargenoteshow"
      # redirect_to eval("inpatient_ipd_record_discharge_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id,admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'show')")
      redirect_to controller: "inpatient/ipd_record/discharge_note/#{@speciality_folder_name}_notes", action: 'show', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id.to_s
    when "operativenoteshow"
      # redirect_to eval("inpatient_ipd_record_operative_note_#{@speciality_folder_name}_note_path(id: '#{params[:id]}',admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'show')")
      redirect_to controller: "inpatient/ipd_record/operative_note/#{@speciality_folder_name}_notes", action: 'show', id: params[:id], admission_id: @ipdrecord.admission_id.to_s
    else
      respond_to do |format|
      end
    end
  end

  # def new_clinical_note
  #
  # end
  #
  def create_clinial_note
  end

  def update
    if params[:inpatient_ipd_record][:admission_attributes][:doctor].blank? || params[:inpatient_ipd_record][:admission_attributes][:facility_id].blank? || params[:inpatient_ipd_record][:admission_attributes][:specialty_id].blank?
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'No Doctor or Location Selected', text: 'Please make sure you have selected Location, Doctor and Specialty', type: 'warning' }); notice.get().click(function(){ notice.remove() });" }
      end
    else
      @ipdrecord.update!(ipd_record_params)
      @admission = Admission.find_by(id: @ipdrecord.admission_id)

      # PatientIdentifier and reg_ fields updation
      patient = Patient.find_by(id: @admission.patient_id)
      if patient.try(:reg_status) == false
        patient.update(reg_status: true, reg_date: Date.current, reg_time: Time.current, reg_facility_id: @admission.facility_id.to_s)
        create_patient_identifier(patient, current_user)
        create_patient_search(patient)
      end
      # EOF PatientIdentifier and reg_ fields updation
      respond_to do |format|
        format.js { render "inpatient/ipd_record/admission_note/close" }
      end
      update_patient_timeline
      update_record_history(@ipdrecord.template_type) if @ipdrecord.template_type.present?

      Analytics::CreateService.call(@admission.id.to_s, @admission.doctor.to_s, @admission.facility_id.to_s, 'admitted')
      object_config = {}
      object_config["class_name"] = "ipd_casesheets"
      object_config["method_name"] = "update"
      mandatory = {}
      mandatory["organisation_id"] = current_user["organisation_id"].to_s
      optional = {}
      others = {}
      mandatory["admission_id"] = @ipdrecord.admission_id.to_s
      ProcessInBackgroundJob.set(queue: :urgent, wait_until: 0).perform_later(object_config, mandatory, optional, others)
    end
  end

  private

  def update_patient_timeline
    Patients::Summary::TimelineWorker.call({ event_name: "IPD_ADMISSION", sub_event_name: "ADMITTED", admission_id: @ipdrecord.admission_id, user_id: current_user.id, user_name: current_user.fullname })
  end

  def ipd_record_params
    params.require(:inpatient_ipd_record).permit(
      :id, :organisation_id, :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id,
      :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id,
      :expected_management, :expected_stay, :hospitalization_reason, :complaint_date, :medico_legal_case,
      :medico_legal_details, :payment_type, :facility_id, :doctor_id,
      patient_attributes: [:id, :occupation, :employee_id, :address_1, :address_2, :city, :state, :pincode,
                           :emergencycontactname, :emergencymobilenumber, :blood_group, :maritalstatus],
      admission_attributes: [:id, :admissiondate, :admissiontime, :admissionreason, :managementplan, :facility_id,
                             :doctor, :specialty_id, :patient_arrived, :dischargedate, :admission_stage,
                             admission_milestones_attributes: [:id, :label, :user_id, :position]]
    )
  end

  def patient_params
    params.require(:patient).permit(:id, :occupation, :employee_id, :address_1, :address_2, :city, :state, :pincode, :emergencycontactname, :emergencymobilenumber, :blood_group, :maritalstatus)
  end

  def admission_params
    params.require(:admission).permit(:id, :admissiondate, :admissiontime, :admissionreason, :managementplan, :facility_id, :doctor)
  end

  def find_ipdrecord
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
    unless @ipdrecord.present?
      respond_to do |format|
        format.js { render inline: "notice = new PNotify({ title: 'Warning', text: 'Record not found: Reloading the page ...', type: 'warning' }); notice.get().click(function(){ notice.remove() }); location.reload();"  }
      end
    end
  end

  def find_ipdrecord_for_write
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:inpatient_ipd_record][:admission_id])
    unless @ipdrecord.present?
      respond_to do |format|
        format.js { render inline: "notice = new PNotify({ title: 'Warning', text: 'Record not found: Reloading the page ...', type: 'warning' }); notice.get().click(function(){ notice.remove() }); location.reload();"  }
      end
    end
  end

  def find_patient
    @patient = @ipdrecord.patient
  end

  def find_tpa
    @tpa = @admission
  end

  def find_admission
    if @ipdrecord.present?
      @admission = @ipdrecord.admission
    else
      respond_to do |format|
        format.js { render inline: "notice = new PNotify({ title: 'Warning', text: 'Record not found: Reloading the page ...', type: 'warning' }); notice.get().click(function(){ notice.remove() }); location.reload();"  }
      end
    end
  end

  def find_templatetype
    @template_type = params[:templatetype]
  end

  def admission_note_form_params
    @current_facility = current_facility
    @ward_count = Ward.where(facility_id: @current_facility.id).count
    if @ward_count < 0 || @admission.daycare
      @bed_details = "Daycare"
    else
      ward, room, bed = @admission.set_bed_details
      @bed_details = "#{bed&.code}(#{ward&.name}/#{room&.name})"
    end

    # For Case Open All Notes Before Admitting
    # @clinical_note = Inpatient::IpdRecord::ClinicalNote.find_by(admission_id: @admission.id)
  end

  def find_patient_details
    @patient_identifier_id = @patient.patient_identifier_id
    @patient_mrn = @patient.patient_mrn
    @age_gender = @patient.patient_age_gender
  end

  def create_record_history
  end

  def update_record_history(tempaltetype)
    @ipdrecord.record_histories.create(:user_id => current_user.id, :action => "U", :actiontime => Time.current, :template_type => tempaltetype)
  end

  def get_admission_note_params
    facility = Facility.find_by(id: @admission.facility_id)
    @available_specialties = Specialty.where(:id.in => facility.specialty_ids & current_user.specialty_ids).pluck(:name, :id).sort
    @selected_specialty = @admission.specialty_id || @available_specialties.first.id.to_s
    @available_doctors = User.where(facility_ids: @admission.facility_id, role_ids: 158965000, specialty_ids: @selected_specialty, is_active: true).pluck("fullname", "id")
  end

  def create_patient_identifier(patient, current_user)
    patient_identifier = PatientIdentifier.create!(patient_id: patient.id, organisation_id: current_user.organisation_id, bkp_patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
    patient_org_id = SequenceManagers::GenerateSequenceService.call('patient', patient.id.to_s, {organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id.to_s, region_id: current_facility.try(:region_master_id).to_s})
      patient_identifier.update(patient_org_id: patient_org_id)
  end
  # EOF create_patient_identifier

  def create_patient_search(patient)
    patient_name = "#{patient.firstname} #{patient.middlename} #{patient.lastname}".strip
    patient_name_search = patient_name.tr('^A-Za-z0-9', '').downcase
    mobile_number = patient.mobilenumber
    mr_no = patient.patient_mrn
    mr_no_search = mr_no.to_s.tr('^A-Za-z0-9', '') # .split("").map {|x| x[/\d+/]}.join("")
    reg_hosp_ids = patient.reg_hosp_ids
    patient_identifier_id = patient.patient_identifier_id
    patient_identifier_id_search = patient_identifier_id.to_s.split('').map { |x| x[/\d+/] }.join('')

    search = "#{mobile_number} #{mr_no_search} #{patient_identifier_id_search} #{patient_name}"
    search += "#{mr_no_search} #{mobile_number} #{patient_name} #{patient_identifier_id_search}"
    search += "#{patient_identifier_id_search} #{patient_name} #{mobile_number} #{mr_no_search}"
    search += "#{patient_name} #{patient_identifier_id_search} #{mr_no_search} #{mobile_number}"

    PatientSearch.create(search: search.downcase, patient_id: patient.id, 
                        patient_name: patient_name, mobile_number: mobile_number, 
                        mr_no: patient.patient_mrn, 
                        patient_identifier_id: patient_identifier_id, 
                        reg_hosp_ids: reg_hosp_ids, 
                        patient_identifier_id_search: patient_identifier_id_search,
                        mr_no_search: mr_no_search.downcase, 
                        patient_name_search: patient_name_search)
  end
  # EOF create_patient_search
end
