class CounsellorRecordsController < ApplicationController
  before_action :authorize
  before_action :current_user_facility
  before_action :get_counsellors
  before_action :get_counsellor_record, only: [:show, :edit, :update]
  before_action :get_patient, only: [:new, :create, :show, :edit, :update]
  before_action :get_appointment, only: [:new, :create, :show, :edit, :update]
  before_action :get_case_sheet, only: [:new, :edit]
  before_action :get_surgery_packages, only: [:new, :edit]
  before_action :get_insurance_values, only: [:new, :edit]
  before_action :legacy_data, only: [:show]

  def new
    @counsellor_record = CounsellorRecord.new
  end

  def create
    set_insurance_params

    @counsellor_record = CounsellorRecord.new(counsellor_record_params)

    @existing_record = CounsellorRecord.find_by(id: @counsellor_record.id)
    @counsellor_record = @existing_record if @existing_record.present?

    if @counsellor_record.save
      @case_sheet = CaseSheet.find_by(id: @counsellor_record.case_sheet_id)
      render 'show'

      CounsellorRecordJobs::PatientCounselledJob.perform_later(@counsellor_record.id.to_s)

      create_new_patient_insurance
      Patients::Summary::TimelineWorker.call({ event_name: "COUNSELLOR_RECORD", sub_event_name: "CREATED", counsellor_record_id: @counsellor_record.id, user_id: current_user.id, user_name: current_user.fullname })
    else
      render 'new'
    end
  end

  def show
    @view_from = params[:view_from]
    @case_sheet = CaseSheet.find_by(id: @counsellor_record.case_sheet_id)
  end

  def edit
  end

  def update
    set_insurance_params

    params[:counsellor_record][:patient_surgery_package] = params[:counsellor_record][:patient_surgery_package] || {}
    if @counsellor_record.update_attributes(counsellor_record_params)
      @case_sheet = CaseSheet.find_by(id: @counsellor_record.case_sheet_id)

      render 'show'

      CounsellorRecordJobs::PatientCounselledJob.perform_later(@counsellor_record.id.to_s)

      create_new_patient_insurance

      Patients::Summary::TimelineWorker.call({ event_name: "COUNSELLOR_RECORD", sub_event_name: "UPDATED", counsellor_record_id: @counsellor_record.id, user_id: current_user.id, user_name: current_user.fullname })
    else
      render 'edit'
    end
  end

  def get_procedure_details
    @counter = params[:counter]
    # @procedure = eval(params[:procedure_type]).find_by(code: params[:code])
    procedure_type = get_procedure_type(params[:procedure_type])
    @procedure = procedure_type.constantize.find_by(code: params[:code])

    if @procedure.present?
      respond_to do |format|
        format.html { render partial: "counsellor_records/forms/get_procedure_details.html.erb" }
      end
    else
      head :ok
    end
  end

  def get_ophthal_investigation_details
    @counter = params[:counter]
    # @ophthal_investigation = eval(params[:investigation_type]).find_by(investigation_id: params[:investigation_id])
    investigation_type = get_investigation_type(params[:investigation_type])
    @ophthal_investigation = investigation_type.constantize.find_by(investigation_id: params[:investigation_id])

    if @ophthal_investigation.present?
      respond_to do |format|
        format.html { render partial: "counsellor_records/forms/get_ophthal_investigation_details.html.erb" }
      end
    else
      head :ok
    end
  end

  def get_laboratory_investigation_details
    @counter = params[:counter]
    # @laboratory_investigation = params[:investigation_type].constantize.find_by(investigation_id: params[:investigation_id])
    investigation_type = get_investigation_type(params[:investigation_type])
    @laboratory_investigation = investigation_type.constantize.find_by(investigation_id: params[:investigation_id])

    if @laboratory_investigation.present?
      respond_to do |format|
        format.html { render partial: "counsellor_records/forms/get_laboratory_investigation_details.html.erb" }
      end
    else
      head :ok
    end
  end

  def get_radiology_investigation_details
    @counter = params[:counter]
    # @radiology_investigation = params[:investigation_type].constantize.find_by(investigation_id: params[:investigation_id].to_i)
    investigation_type = get_investigation_type(params[:investigation_type])
    @radiology_investigation = investigation_type.constantize.find_by(investigation_id: params[:investigation_id].to_i)

    if @radiology_investigation.present?
      respond_to do |format|
        format.html { render partial: "counsellor_records/forms/get_radiology_investigation_details.html.erb" }
      end
    else
      head :ok
    end
  end

  def get_surgery_package_details
    @surgery_package = SurgeryPackage.find_by(id: params[:surgery_package_id])

    unless @surgery_package.present?
      @counsellor_record = CounsellorRecord.find_by(id: params[:counsellor_record_id])
    end
    if @surgery_package.present? || @counsellor_record.present?
      respond_to do |format|
        format.html { render partial: "counsellor_records/forms/get_surgery_package_details.html.erb" }
      end
    else
      head :ok
    end
  end

  private

  def get_insurance_values
    @insurance_contact = ContactGroup.find_by(organisation_id: current_user.organisation_id, contact_group_type: 'tpa', name: 'Insurance')
    @insurance_contacts = Contact.where(is_deleted: false, organisation_id: current_user.organisation_id, contact_group_id: @insurance_contact.try(:id))

    @current_insurances = PatientInsurance.where(patient_id: @patient.try(:id))
  end

  def set_insurance_params
    if params[:counsellor_record][:patient_insurance_id].present?
      params[:counsellor_record][:insurance_contact_id] = params[:hidden_insurance_contact_id]
      params[:counsellor_record][:insurance_name] = params[:hidden_insurance_name]
      params[:counsellor_record][:insurance_contact_no] = params[:hidden_insurance_contact_no]
      params[:counsellor_record][:insurance_contact_person] = params[:hidden_insurance_contact_person]
      params[:counsellor_record][:insurance_address] = params[:hidden_insurance_address]
      params[:counsellor_record][:insurance_policy_no] = params[:hidden_insurance_policy_no]
      params[:counsellor_record][:insurance_policy_expiry_date] = params[:hidden_insurance_policy_expiry_date]
    end
  end

  def create_new_patient_insurance
    unless params[:counsellor_record][:patient_insurance_id].present?
      if params[:counsellor_record][:is_insured] == "Yes"
        @insurance = PatientInsurance.new(patient_insurance_params)
        if @insurance.save
          @counsellor_record.update(patient_insurance_id: @insurance.id)
        end
      end
    end
  end

  def counsellor_record_params
    params.require(:counsellor_record).permit! # (:history_comment, :diagnosis_comment, :investigation_comment, :procedure_comment, :patient_id, :appointment_id, :user_id, :facility_id, :organisation_id, opd_record_ids: [], diagnoses: [:name, :icddiagnosiscode, :saperatedicddiagnosiscode], ophthal_investigations: [:name, :side, :fullcode, :stage, :is_counselled, :counselled_at, :counselled_by, :converted_at, :is_converted, :converted_at, :converted_by, :opd_investigation_id], laboratory_investigations: [:name, :loinc_code, :loinc_class, :investigation_id, :stage, :is_counselled, :counselled_at, :counselled_by, :converted_at, :is_converted, :converted_at, :converted_by, :opd_investigation_id], radiology_investigations: [:name, :radiology_options, :loinc_code, :full_code, :stage, :is_counselled, :counselled_at, :counselled_by, :converted_at, :is_converted, :converted_at, :converted_by, :opd_investigation_id, :investigation_id], procedures: [:name, :procedure_id, :side, :full_code, :stage, :is_counselled, :counselled_at, :counselled_by, :converted_at, :is_converted, :converted_at, :converted_by], patient_discussions: [:note, :note_date])
  end

  def patient_insurance_params
    params.require(:counsellor_record).permit(:patient_id, :organisation_id, :facility_id, :insurance_contact_id, :insurance_name, :insurance_address, :insurance_email, :insurance_contact_no, :insurance_contact_person, :insurance_policy_no, :insurance_policy_expiry_date, :admission_id, :insurance_sum_insured)
  end

  def current_user_facility
    @current_user = current_user
    @current_facility = current_facility
  end

  def get_counsellors
    @counsellors = User.where(facility_ids: current_facility.id, role_ids: 499992366, is_active: true)
    @counsellor_options = @counsellors.pluck(:fullname, :id)
  end

  def get_counsellor_record
    @counsellor_record = CounsellorRecord.find_by(id: params[:id])
  end

  def get_appointment
    @appointment = Appointment.find_by(id: params[:appointment_id])
  end

  def get_patient
    @patient = Patient.find_by(id: params[:patient_id])
    @patient_history = @patient.try(:patient_history)
  end

  def get_case_sheet
    @case_sheet = CaseSheet.find_by(id: @appointment.case_sheet_id)
  end

  def get_surgery_packages
    @surgery_packages = SurgeryPackage.where(facility_id: current_facility.id, is_active: true)
  end

  def legacy_data # For Old CounsellorRecord Structure
    if @counsellor_record.is_legacy
      @last_opdrecord = OpdRecord.where(patientid: @patient.id.to_s).order("created_at DESC")[0]
      @print_procedure = []
      @print_investigation = []
      if @last_opdrecord.present?
        @last_opdrecord.procedure.where(counselling: true).each do |i|
          @print_procedure << i.procedurename + "(" + @last_opdrecord.get_label_for_procedure_side(i.procedureside) + ")"
        end
        @last_opdrecord.ophthalinvestigationlist.where(counselling: true).each do |i|
          @print_investigation << i.investigationname + "(" + @last_opdrecord.get_label_for_ophthalinvestigations_side(i.investigationside) + ")"
        end
      end
    end
  end

  def get_procedure_type(procedure_type)
    ['CustomCommonProcedure', 'CommonProcedure', 'SynonymCommonProcedure', 'TranslatedCommonProcedure'].select{|procedure| procedure == procedure_type}.first
  end
  # EOF get_procedure_type

  def get_investigation_type(investigation_type)
    ['OphthalmologyInvestigationData', 'LaboratoryInvestigationData', 'RadiologyInvestigationData'].select{|investigation| investigation == investigation_type}.first
  end
  # EOF get_investigation_type
end
