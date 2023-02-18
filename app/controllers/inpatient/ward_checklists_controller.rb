class Inpatient::WardChecklistsController < ApplicationController
  before_action :authorize
  before_action :find_ipd_record, only: [:new, :edit, :create, :update]
  before_action :print_settings, only: [:show, :create, :update]

  def new
    @patient_id = params[:patient_id]
    @admission_id = params[:admission_id]
    @procedures = @ipdrecord.try(:procedure)
    @current_user = current_user
    @current_facility = current_facility
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:specialty_id])
    @specalityid = params[:specialty_id].to_i
    @ward_checklist = Inpatient::WardChecklist.new
  end

  def create
    @ward_checklist = Inpatient::WardChecklist.new(ward_checklist_params)
    @patient = Patient.find_by(id: ward_checklist_params[:patient_id])
    @admission = Admission.find_by(id: ward_checklist_params[:admission_id])
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@ward_checklist.specalityid)
    if @ward_checklist.save
      @admission.inc(ipd_templates_count: 1)
      @ward_checklist.record_histories.create(:user_id => current_user.id, :action => "C", :actiontime => Time.current, :template_type => "ward_checklist")
      # @ward_checklist = WardChecklist.find_by(admission_id: ward_checklist_params[:admission_id])
      respond_to do |format|
        format.js { render 'create.js.erb' }
      end
      Patients::Summary::TimelineWorker.call(event_name: 'NURSING_RECORD', sub_event_name: 'CREATED',
                                             ward_checklist_id: @ward_checklist.id, user_id: current_user.id,
                                             user_name: current_user.fullname, templatetype: 'ward_checklist')
    else
      respond_to do |format|
        format.js { render 'inpatients/ward_checklists/new.js.erb' }
      end
    end
  end

  def edit
    @ward_checklist = Inpatient::WardChecklist.find_by(id: params[:id])
    @procedures = @ipdrecord.procedure
    @current_user = current_user
    @current_facility = current_facility
    @admission = Admission.find_by(id: params[:admission_id])
    specialty_id = params[:specialty_id] || @admission.specialty_id
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(specialty_id)
    @specalityid = params[:specialty_id].to_i
    if @ward_checklist.present?
      @patient_id = @ward_checklist.patient_id
      @admission_id = @ward_checklist.admission_id
    end
  end

  def update
    patient_id = ward_checklist_params[:patient_id]
    admission_id = ward_checklist_params[:admission_id]
    @admission = Admission.find_by(id: admission_id)
    @patient = Patient.find_by(id: patient_id)
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @ward_checklist = Inpatient::WardChecklist.find_by(id: params[:id])
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@ward_checklist.specalityid)
    if @ward_checklist.present?
      if @ward_checklist.update(ward_checklist_params)
        @ward_checklist.record_histories.create(:user_id => current_user.id, :action => "U", :actiontime => Time.current, :template_type => "ward_checklist")
        respond_to do |format|
          format.js { render 'update.js.erb' }
        end
        Patients::Summary::TimelineWorker.call(event_name: 'NURSING_RECORD', sub_event_name: 'UPDATED',
                                               ward_checklist_id: @ward_checklist.id, user_id: current_user.id,
                                               user_name: current_user.fullname, templatetype: 'ward_checklist')
      else
        respond_to do |format|
          format.js { render 'edit.js.erb' }
        end
      end
    end
  end

  def show
    @ward_checklist = Inpatient::WardChecklist.find_by(admission_id: params[:admission_id])
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    if @ward_checklist.present?
      respond_to do |format|
        format.js { render 'show.js.erb' }
      end
    end
  end

  def print
    @current_facility = current_facility
    @admission = Admission.find_by(id: params[:admission_id])
    @patient = Patient.find_by(id: params[:patient_id])
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @ward_checklist = Inpatient::WardChecklist.find_by(admission_id: params[:admission_id])
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      format.pdf { render template: 'inpatient/ward_checklists/print.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
  end

  private

  def find_ipd_record
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
  end

  def ward_checklist_params
    params.require(:inpatient_ward_checklist).permit!
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['486546481'])
  end
end
