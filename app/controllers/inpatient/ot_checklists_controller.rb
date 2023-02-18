class Inpatient::OtChecklistsController < ApplicationController
  before_action :authorize
  before_action :find_ipd_record, only: [:new, :edit, :create, :update, :show, :print]
  before_action :print_settings, only: [:show, :create, :update]

  def new
    @patient_id = params[:patient_id]
    @admission_id = params[:admission_id]
    @procedures = @ipdrecord.procedure
    @current_user = current_user
    @current_facility = current_facility
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:specialty_id])
    @specalityid = params[:specialty_id].to_i
    @ot_checklist = OtChecklist.new
    respond_to do |format|
      format.js { render "inpatients/ot_checklist.js.erb" }
    end
  end

  def create
    if params[:ipd_record] && params[:ipd_record][:procedure].present? && (params[:ipd_record][:procedure].to_unsafe_h.map { |k, v| v[:ot_checklist] }.uniq == ["false"])
      if params[:ipd_record][:procedure].to_unsafe_h.map { |k, v| v[:ot_checklist] }.uniq == ["false"]
        js_notify = "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'Cannot create Surgical Checklist without selected procedure', type: 'warning' }); notice.get().click(function(){ notice.remove() }); $('.surgery-step').trigger('click');"
      end
      respond_to do |format|
        format.js { render js: js_notify }
      end
    else
      @ot_checklist = OtChecklist.new(ot_checklist_params)
      @patient_id = ot_checklist_params[:patient_id]
      @patient = Patient.find_by(id: @patient_id)
      @admission = Admission.find_by(id: ot_checklist_params[:admission_id])
      @referral = PatientReferralType.find_by(patient_id: @patient.id)
      if @ot_checklist.save
        @admission.inc(ipd_templates_count: 1)
        @ot_checklist.record_histories.create(:user_id => current_user.id, :action => "C", :actiontime => Time.current, :template_type => "otchecklist")
        @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
        IpdRecords::UpdateService.update_checklist_inprocedure(@ipdrecord, @ot_checklist, params[:ipd_record]) if params[:ipd_record].present?
        Patients::Summary::TimelineWorker.call({ event_name: "NURSING_RECORD", sub_event_name: "CREATED", ot_checklist_id: @ot_checklist.id, user_id: current_user.id, user_name: current_user.fullname, templatetype: 'otchecklist' })
        respond_to do |format|
          format.js { render "inpatients/ot_checklists/save.js.erb" }
        end
      else
        respond_to do |format|
          format.js { render "inpatients/ot_checklist.js.erb" }
        end
      end
    end
  end

  def edit
    @patient_id = params[:patient_id]
    @admission_id = params[:admission_id]
    @admission = Admission.find_by(id: @admission_id)
    @procedures = @ipdrecord&.procedure.to_a
    @current_user = current_user
    @current_facility = current_facility
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@admission.specialty_id)
    @specalityid = @specalityid = params[:specialty_id].to_i
    @ot_checklist = OtChecklist.find_by(id: params[:id])

    if @ot_checklist.present?
      respond_to do |format|
        format.js { render "inpatients/ot_checklist.js.erb" }
      end
    end
  end

  def update
    if params[:ipd_record] && params[:ipd_record][:procedure].present? && (params[:ipd_record][:procedure].to_unsafe_h.map { |k, v| v[:ot_checklist] }.uniq == ["false"])
      if params[:ipd_record][:procedure].to_unsafe_h.map { |k, v| v[:ot_checklist] }.uniq == ["false"]
        js_notify = "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'Cannot create Surgical Checklist without selected procedure', type: 'warning' }); notice.get().click(function(){ notice.remove() }); $('.surgery-step').trigger('click');"
      end
      respond_to do |format|
        format.js { render js: js_notify }
      end
    else
      @admission = Admission.find_by(id: ot_checklist_params[:admission_id])
      @patient_id= ot_checklist_params[:patient_id]
      @patient = Patient.find_by(id: @patient_id)
      @referral = PatientReferralType.find_by(patient_id: @patient.id)
      @ot_checklist = OtChecklist.find_by(id: ot_checklist_params[:id])
      @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
      if @ot_checklist.present?
        if @ot_checklist.update(ot_checklist_params)
          @ot_checklist.record_histories.create(:user_id => current_user.id, :action => "U", :actiontime => Time.current, :template_type => "otchecklist")
          IpdRecords::UpdateService.update_checklist_inprocedure(@ipdrecord, @ot_checklist, params[:ipd_record]) if params[:ipd_record].present?
          Patients::Summary::TimelineWorker.call({ event_name: "NURSING_RECORD", sub_event_name: "UPDATED", ot_checklist_id: @ot_checklist.id, user_id: current_user.id, user_name: current_user.fullname, templatetype: 'otchecklist' })
          respond_to do |format|
            format.js { render "inpatients/ot_checklists/save.js.erb" }
          end
        else
          respond_to do |format|
            format.js { render "inpatients/ot_checklist.js.erb" }
          end
        end
      end
    end
  end

  def show
    @patient_id = params[:patient_id]
    @patient = Patient.find_by(id: @patient_id)
    @admission_id = params[:admission_id]
    @admission = Admission.find_by(id: @admission_id)
    @procedures = @ipdrecord&.procedure.to_a
    @current_user = current_user
    @current_facility = current_facility
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@admission.specialty_id)
    @specalityid = @specalityid = params[:specialty_id].to_i
    @ot_checklist = OtChecklist.find_by(id: params[:id])
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    if @ot_checklist.present?
      respond_to do |format|
        format.js { render 'inpatients/ot_checklists/show.js.erb' }
      end
    end
  end

  def print
    patient_id = params[:patient_id]
    admission_id = params[:admission_id]
    @admission = Admission.find_by(id: admission_id)
    @patient = Patient.find_by(id: patient_id)
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @ot_checklist = OtChecklist.find_by(admission_id: admission_id)
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      format.pdf { render template: 'inpatients/ot_checklists/print.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
  end

  private

  def find_ipd_record
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
  end

  def ot_checklist_params
    params.require(:ot_checklist).permit!
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['486546481'])
  end
end
