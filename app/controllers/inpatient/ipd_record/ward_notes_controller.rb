class Inpatient::IpdRecord::WardNotesController < ApplicationController
  before_action :authorize
  before_action :find_ipd_record, only: [:new, :edit, :print, :show, :index]
  before_action :find_ipd_record_for_write, only: [:create, :update]
  before_action :ward_note_form_params, only: [:new, :edit]
  before_action :ward_note, only: [:edit]
  before_action :ward_note_for_write, only: [:update]

  def new
    if params[:clone]
      @ward_note = @ipdrecord.ward_notes.find_by(:id => params[:ward_note_id])
      @ward_note = @ward_note.clone
      @ward_note.created_at = Time.current.utc
      @ward_note.updated_at = Time.current.utc
    else
      @ward_note = @ipdrecord.ward_notes.new
    end
    @url = "/inpatient/ipd_record/ward_note/#{@speciality_folder_name}_notes"
    @method = "POST"
    respond_to do |format|
      format.js { render "inpatient/ipd_record/ward_note/form" }
    end
  end

  def create
    @current_facility = current_facility
    if @ipdrecord.update(ward_note_params)
      @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@ipdrecord.specialty_id)
      WardNoteAssessmentJob.perform_later(@ipdrecord.admission_id.to_s, @ipdrecord.patient_id.to_s, current_user.id.to_s)
      @ward_note = @ipdrecord.ward_notes[-1]
      @ward_note.record_histories.create(user_id: current_user.id, action: "C", actiontime: Time.current, template_type: "Ward Note")
      ward_note_view_params
      respond_to do |format|
        format.js { render "inpatient/ipd_record/ward_note/show" }
      end
      Patients::Summary::TimelineWorker.call({ event_name: "IPD_RECORD", sub_event_name: "CREATED", ipd_record_id: @ipdrecord.id, user_id: current_user.id, user_name: current_user.fullname, ipdtemplatetype: "Ward Note", note_id: @ward_note.id })
      IpdRecordJob.perform_later(@ipdrecord.id.to_s, @ward_note.id.to_s, 'ward_note')
    end
  end

  def index
    @current_facility = current_facility
    ward_note_view_params
    respond_to do |format|
      format.js { render "inpatient/ipd_record/ward_note/show" }
    end
  end

  def edit
    @url = "/inpatient/ipd_record/ward_note/#{@speciality_folder_name}_notes/#{@ipdrecord.id}"
    @method = "PATCH"
    respond_to do |format|
      format.js { render "inpatient/ipd_record/ward_note/form" }
    end
  end

  def update
    @current_facility = current_facility
    if @ipdrecord.update_attributes(ward_note_update_params)
      @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@ipdrecord.specialty_id)
      WardNoteAssessmentJob.perform_later(@ipdrecord.admission_id.to_s, @ipdrecord.patient_id.to_s, current_user.id.to_s)
      @ward_note.record_histories.create(user_id: current_user.id, action: "U", actiontime: Time.current, template_type: "Ward Note")
      ward_note_view_params
      respond_to do |format|
        format.js { render "inpatient/ipd_record/ward_note/show" }
      end

      Patients::Summary::TimelineWorker.call({ event_name: "IPD_RECORD", sub_event_name: "UPDATED", ipd_record_id: @ipdrecord.id, user_id: current_user.id, user_name: current_user.fullname, ipdtemplatetype: "Ward Note", note_id: @ward_note.id })
      IpdRecordJob.perform_later(@ipdrecord.id.to_s, @ward_note.id.to_s, 'ward_note')
    end
  end

  def print
    @ward_note = @ipdrecord.ward_notes.find_by(id: params[:id])
    @patient = @ipdrecord.patient
    @admission = @ipdrecord.admission
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, "IPD")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]

    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])

    respond_to do |format|
      format.pdf { render :template => "inpatient/ipd_record/ward_note/print", :pdf => "", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { spacing: 0, html: { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, :top => @print_setting.try(:header_height).to_f * 10, :bottom => @print_setting.try(:footer_height).to_f * 10 } }
    end
  end

  private

  def ward_note_form_params
    current_user = current_user
    @current_facility = current_facility
    @admission = Admission.find_by(id: params[:admission_id])
    @tpa = Inpatient::Insurance::Tpa.find_by(admission_id: @admission.id)
    @patient = @admission.patient
    @patient_identifier_id = @patient.patient_identifier_id
    @patient_mrn = @patient.patient_mrn
    @age_gender = @patient.patient_age_gender
  end

  def ward_note_view_params
    if params[:admission_id]
      @admission = Admission.find_by(id: params[:admission_id])
    else
      @admission = Admission.find_by(id: @ward_note.admission_id)
    end
    @patient = Patient.find_by(id: @admission.patient_id)
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @tpa = Inpatient::Insurance::Tpa.find_by(admission_id: @admission.id)
    @ward_notes = @ipdrecord.ward_notes

    @print_settings = PrintSetting.print_options(current_user.organisation_id, current_facility.id, ["486546481"])
  end

  def ward_note_params
    params.require(:inpatient_ipd_record).permit(:admission_id, ward_notes_attributes: [:note_created_at, :admission_id, :organisation_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :notetext, :anthropometryheight, :anthropometryweight, :anthropometrybmi, :vitalsignstemperature, :vitalsignspulse, :vitalsignsbp, :vitalsignsrr, :vitalsignsspo2])
  end

  def ward_note_update_params
    params.require(:inpatient_ipd_record).permit(:admission_id, ward_notes_attributes: [:id, :note_created_at, :admission_id, :organisation_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :notetext, :anthropometryheight, :anthropometryweight, :anthropometrybmi, :vitalsignstemperature, :vitalsignspulse, :vitalsignsbp, :vitalsignsrr, :vitalsignsspo2])
  end

  def ward_note
    @ward_note = @ipdrecord.ward_notes.find_by(id: params[:id])
  end

  def find_ipd_record
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
  end

  def find_ipd_record_for_write
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:inpatient_ipd_record][:admission_id])
  end

  def ward_note_for_write
    @ward_note = @ipdrecord.ward_notes.find_by(id: params[:inpatient_ipd_record][:ward_notes_attributes]["0"][:id])
  end
end
