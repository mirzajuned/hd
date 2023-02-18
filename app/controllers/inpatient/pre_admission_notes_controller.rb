class Inpatient::PreAdmissionNotesController < ApplicationController
  before_action :authorize
  before_action :find_ipd_record, only: [:new, :edit, :create, :update]
  before_action :print_settings, only: [:show, :create, :update]

  def new
    @patient_id = params[:patient_id]
    @admission_id = params[:admission_id]
    @procedures = @ipdrecord.procedure


    @pre_admission_instruction_notes = PreAdmissionInstructionNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)
    @pre_admission_medication_notes = PreAdmissionMedicationNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)
    @pre_admission_investigation_notes = PreAdmissionInvestigationNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)
    @pre_admission_special_notes = PreAdmissionSpecialNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)

    @current_user = current_user
    @current_facility = current_facility
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:specialty_id])
    @specalityid = params[:specialty_id].to_i
    @pre_admission_note = Inpatient::PreAdmissionNote.new
  end

  def create
    @pre_admission_note = Inpatient::PreAdmissionNote.new(pre_admission_note_params)
    @pre_admission_special_notes = PreAdmissionSpecialNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)
    @patient = Patient.find_by(id: pre_admission_note_params[:patient_id])
    @admission = Admission.find_by(id: pre_admission_note_params[:admission_id])
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@pre_admission_note.specalityid)
    if @pre_admission_note.save
      @admission.inc(ipd_templates_count: 1)
      @pre_admission_note.record_histories.create(:user_id => current_user.id, :action => "C", :actiontime => Time.current, :template_type => "pre_admission_note")
      # @pre_admission_note = PreAdmissionNote.find_by(admission_id: pre_admission_note_params[:admission_id])
      respond_to do |format|
        format.js { render 'create.js.erb' }
      end
      # Patients::Summary::TimelineWorker.call(event_name: 'NURSING_RECORD', sub_event_name: 'CREATED',
      #                                        pre_admission_note_id: @pre_admission_note.id,
      #                                        user_id: current_user.id, user_name: current_user.fullname,
      #                                        templatetype: 'pre_admission_note')
    else
      respond_to do |format|
        format.js { render 'inpatients/pre_admission_notes/new.js.erb' }
      end
    end
  end

  def edit
    @pre_admission_note = Inpatient::PreAdmissionNote.find_by(id: params[:id])
    @procedures = @ipdrecord.procedure

    @pre_admission_instruction_notes = PreAdmissionInstructionNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)
    @pre_admission_medication_notes = PreAdmissionMedicationNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)
    @pre_admission_investigation_notes = PreAdmissionInvestigationNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)
    @pre_admission_special_notes = PreAdmissionSpecialNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)

    @current_user = current_user
    @current_facility = current_facility
    @admission = Admission.find_by(id: params[:admission_id])
    specialty_id = params[:specialty_id] || @admission.specialty_id
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(specialty_id)
    @specalityid = params[:specialty_id].to_i
    if @pre_admission_note.present?
      @patient_id = @pre_admission_note.patient_id
      @admission_id = @pre_admission_note.admission_id
    end
  end

  def update
    patient_id = pre_admission_note_params[:patient_id]
    admission_id = pre_admission_note_params[:admission_id]
    @admission = Admission.find_by(id: admission_id)
    @patient = Patient.find_by(id: patient_id)
    @pre_admission_note = Inpatient::PreAdmissionNote.find_by(id: params[:id])
    @pre_admission_special_notes = PreAdmissionSpecialNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)

    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@pre_admission_note.specalityid)
    if @pre_admission_note.present?
      if @pre_admission_note.update(pre_admission_note_params)
        @pre_admission_note.record_histories.create(:user_id => current_user.id, :action => "U", :actiontime => Time.current, :template_type => "pre_admission_note")
        respond_to do |format|
          format.js { render 'update.js.erb' }
        end
        # Patients::Summary::TimelineWorker.call(event_name: 'NURSING_RECORD', sub_event_name: 'UPDATED',
        #                                        pre_admission_note_id: @pre_admission_note.id,
        #                                        user_id: current_user.id, user_name: current_user.fullname,
        #                                        templatetype: 'pre_admission_note')
      else
        respond_to do |format|
          format.js { render 'edit.js.erb' }
        end
      end
    end
  end

  def show
    @pre_admission_note = Inpatient::PreAdmissionNote.find_by(admission_id: params[:admission_id])
    @pre_admission_special_notes = PreAdmissionSpecialNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)

    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    if @pre_admission_note.present?
      respond_to do |format|
        format.js { render 'show.js.erb' }
      end
    end
  end

  def print
    patient_id = params[:patient_id]
    admission_id = params[:admission_id]
    @admission = Admission.find_by(id: admission_id)
    @patient = Patient.find_by(id: patient_id)
    @pre_admission_note = Inpatient::PreAdmissionNote.find_by(admission_id: admission_id)
    @pre_admission_special_notes = PreAdmissionSpecialNote.where(is_active: true, level: "organisation", organisation_id: current_user.organisation_id)

    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      format.pdf { render template: 'inpatient/pre_admission_notes/print.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
  end

  private

  def find_ipd_record
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
  end

  def pre_admission_note_params
    params.require(:inpatient_pre_admission_note).permit!
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['486546481'])
  end
end
