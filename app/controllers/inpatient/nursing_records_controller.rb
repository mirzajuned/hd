# 5  Metrics/AbcSize
# 2  Metrics/MethodLength
# 1  Metrics/ClassLength
# --
# 8  Total Offenses Pending
class Inpatient::NursingRecordsController < ApplicationController
  before_action :authorize
  before_action :print_settings, only: [:show, :create, :update]
  # before_action :inventory_store, only: [:new, :edit]
  include NursingRecordHelper

  # require 'nursing_record_helper'

  def new
    @patient_id = params[:patient_id]
    @admission_id = params[:admission_id]
    @templatetype = params[:templatetype]
    @current_user = current_user
    @current_facility = current_facility
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:specialty_id])
    @specalityid = params[:specialty_id].to_i
    @form_name, @templateid = form_name
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }
    @nursing_record = NursingRecord.new
    respond_to do |format|
      format.js { render 'inpatients/nursing_record.js.erb' }
    end
  end

  def create
    @nursing_record = NursingRecord.new(nursing_record_params)

    @existing_record = NursingRecord.find_by(id: @nursing_record.id)
    @nursing_record = @existing_record if @existing_record.present?

    @patient = Patient.find_by(id: nursing_record_params[:patient_id])
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @admission = Admission.find_by(id: nursing_record_params[:admission_id])
    @templatetype = nursing_record_params[:template_type]
    @form_name, @templateid = form_name
    @nursing_record.fullname = @form_name
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:nursing_record][:specalityid])

    if @nursing_record.save
      @admission.inc(ipd_templates_count: 1)
      @nursing_record.record_histories.create(user_id: current_user.id, action: 'C',
                                              actiontime: Time.current, template_type: @templatetype)
      respond_to do |format|
        format.js { render 'inpatients/nursing_records/create.js.erb' }
      end
      GenericComposition::CreateService.call(@nursing_record)
      Patients::Summary::TimelineWorker.call(event_name: 'NURSING_RECORD', sub_event_name: 'CREATED',
                                             nursing_record_id: @nursing_record.id, user_id: current_user.id,
                                             user_name: current_user.fullname, templatetype: @templatetype)
    else
      respond_to do |format|
        format.js { render 'inpatients/nursing_record.js.erb' }
      end
    end
  end

  def edit
    @patient_id = params[:patient_id]
    @admission_id = params[:admission_id]
    @templatetype = params[:templatetype]
    @current_user = current_user
    @current_facility = current_facility
    @nursing_record = NursingRecord.find_by(id: params[:id])
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@nursing_record.specalityid)
    @specalityid = @nursing_record.specalityid.to_i
    @form_name, @templateid = form_name
    # @pharmacy_prescription = PatientPrescription.find_by(record_id: BSON::ObjectId(params[:id]), patient_id: @patient_id)
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }

    respond_to do |format|
      format.js { render 'inpatients/nursing_record.js.erb' }
    end
  end

  def update
    @patient = Patient.find_by(id: nursing_record_params[:patient_id])
    @admission = Admission.find_by(id: nursing_record_params[:admission_id])
    @templatetype = nursing_record_params[:template_type]
    @nursing_record = NursingRecord.find_by(id: nursing_record_params[:id])
    @form_name, @templateid = form_name
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:nursing_record][:specalityid])
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    if @nursing_record.update!(nursing_record_params)
      @nursing_record.record_histories.create(user_id: current_user.id, action: 'U',
                                              actiontime: Time.current, template_type: @templatetype)
      respond_to do |format|
        format.js { render 'inpatients/nursing_records/update.js.erb' }
      end
      GenericComposition::CreateService.call(@nursing_record)
      Patients::Summary::TimelineWorker.call(event_name: 'NURSING_RECORD', sub_event_name: 'UPDATED',
                                             nursing_record_id: @nursing_record.id, user_id: current_user.id,
                                             user_name: current_user.fullname, templatetype: @templatetype)
    else
      respond_to do |format|
        format.js { render 'inpatients/nursing_record.js.erb' }
      end
    end
  end

  def print
    patient_id = params[:patient_id]
    admission_id = params[:admission_id]
    @language_flag = params[:language_flag]
    @advice_language = params[:advice_language]
    @admission = Admission.find_by(id: admission_id)
    @patient_exit_time = @admission&.dischargetime&.in_time_zone(current_facility.time_zone)
    @patient = Patient.find_by(id: patient_id)
    @templatetype = params[:templatetype]
    @form_name, @templateid = form_name
    @nursing_record = NursingRecord.find_by(id: params[:id])
    @current_facility = current_facility
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      print_attributes(format, 'inpatients/nursing_records/print', '', @print_setting)
    end
  end

  def show
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @templatetype = params[:templatetype]
    @nursing_record = NursingRecord.find_by(id: params[:id])
    @form_name, @templateid = form_name
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    respond_to do |format|
      format.js { render 'inpatients/nursing_records/show.js.erb' }
    end
  end

  # IPD
  def add_medication
    @counter = params[:ajax][:counter]
    @speciality_folder_name = params[:ajax][:specalityfoldername]
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }
    @medication_instruction_set << 'Add a text Box'
    respond_to do |format|
      format.js { render 'inpatients/nursing_records/add_medication.js.erb', layout: false }
    end
  end

  def add_sedation
    @counter = params[:ajax][:counter]
    respond_to do |format|
      format.js { render 'inpatients/nursing_records/add_sedation.js.erb', layout: false }
    end
  end

  def replace_medication_instruction
    @nursing_record = NursingRecord.find_by(id: params[:id])
    @patient = Patient.find_by(id: @nursing_record.patient_id)
    @specality = @nursing_record.specalityname
    @advice_language = params[:advice_language]
    @language_name = Language.find_by(lcid_code: @advice_language)
    @patient.update(primary_language: @language_name.name)
    respond_to do |format|
      format.js { render 'inpatients/nursing_records/replace_medication_instruction', layout: false }
    end
  end

  private

  def form_name
    if @templatetype == 'aldrete'
      form_name = 'MODIFIED ALDRETE SCORE FOR DISCHARGE'
      templateid = '448226000'
    elsif @templatetype == 'careplan'
      form_name = 'Nursing Care Plan Documentation'
      templateid = '734163000'
    elsif @templatetype == 'pain'
      form_name = 'Pain Assessment(Post Operative)'
      templateid = '225399009'
    elsif @templatetype == 'sedation'
      form_name = 'SEDATION / ANALGESIA MONITORING CHART'
      templateid = '72641008'
    end

    [form_name, templateid]
  end

  def nursing_record_params
    params.require(:nursing_record).permit!
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['486546481'])
  end

  # def inventory_store
  #   @stores_array = Inventory::Store.where(facility_id: current_facility.id, is_active: true,
  #                                          department_id: '284748001').pluck(:name, :id)
  # end
end
