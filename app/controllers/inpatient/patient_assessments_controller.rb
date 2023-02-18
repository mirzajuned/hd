class Inpatient::PatientAssessmentsController < ApplicationController
  before_action :authorize
  before_action :print_settings, only: [:show, :create, :update]
  before_action :set_current_facility, only: [:create, :update, :show, :print]

  def new
    @patient_id = params[:patient_id]
    @admission_id = params[:admission_id]
    @assessment = PatientAssessment.new
    respond_to do |format|
      format.js { render "inpatients/patient_assessment.js.erb" }
    end
  end

  def create
    @patient_assessment = PatientAssessment.new(patient_assessment_params)
    @patient = Patient.find_by(id: patient_assessment_params[:patient_id])
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @admission = Admission.find_by(id: patient_assessment_params[:admission_id])
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@patient_assessment.specialty_id)
    if @patient_assessment.save
      @admission.inc(ipd_templates_count: 1)
      @patient_assessment.record_histories.create(:user_id => current_user.id, :action => "C", :actiontime => Time.current, :template_type => "assessment")
      PatientAssessmentJob.perform_later(@admission.id.to_s, @patient.id.to_s, current_user.id.to_s)
      @assessment = PatientAssessment.find_by(admission_id: patient_assessment_params[:admission_id])
      respond_to do |format|
        format.js { render "inpatients/patient_assessments/create.js.erb" }
      end
      Patients::Summary::TimelineWorker.call({ event_name: "NURSING_RECORD", sub_event_name: "CREATED", assessment_id: @assessment.id, user_id: current_user.id, user_name: current_user.fullname, templatetype: 'assessment' })
    else
      respond_to do |format|
        format.js { render "inpatients/patient_assessment.js.erb" }
      end
    end
  end

  def edit
    @patient_id = params[:patient_id]
    @admission_id = params[:admission_id]
    @assessment = PatientAssessment.find_by(admission_id: @admission_id)

    if @assessment.present?
      respond_to do |format|
        format.js { render "inpatients/patient_assessment.js.erb" }
      end
    end
  end

  def update
    patient_id = patient_assessment_params[:patient_id]
    admission_id = patient_assessment_params[:admission_id]
    @admission = Admission.find_by(id: admission_id)
    @patient = Patient.find_by(id: patient_id)
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @assessment = PatientAssessment.find_by(admission_id: admission_id)
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@assessment.specialty_id)
    if @assessment.present?
      PatientAssessmentJob.perform_later(@admission.id.to_s, @patient.id.to_s, current_user.id.to_s)
      if @assessment.update(patient_assessment_params)
        @assessment.record_histories.create(:user_id => current_user.id, :action => "U", :actiontime => Time.current, :template_type => "assessment")
        respond_to do |format|
          format.js { render "inpatients/patient_assessments/update.js.erb" }
        end
        Patients::Summary::TimelineWorker.call({ event_name: "NURSING_RECORD", sub_event_name: "UPDATED", assessment_id: @assessment.id, user_id: current_user.id, user_name: current_user.fullname, templatetype: 'assessment' })
      else
        respond_to do |format|
          format.js { render "inpatients/patient_assessment.js.erb" }
        end
      end
    end
  end

  def show
    @assessment = PatientAssessment.find_by(admission_id: params[:admission_id])
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    if @assessment.present?
      respond_to do |format|
        format.js { render "inpatients/patient_assessments/show.js.erb" }
      end
    end
  end

  def print
    patient_id = params[:patient_id]
    admission_id = params[:admission_id]
    @admission = Admission.find_by(id: admission_id)
    @patient = Patient.find_by(id: patient_id)
    @assessment = PatientAssessment.find_by(admission_id: admission_id)
    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, "IPD")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      format.pdf { render :template => "inpatients/patient_assessments/print.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, :top => @print_setting.try(:header_height).to_i * 10, :bottom => @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
  end

  private

  def patient_assessment_params
    params.require(:patient_assessment).permit!
  end

  def print_settings
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ["486546481"])
  end

  def set_current_facility
    @current_facility = current_facility
  end
end
