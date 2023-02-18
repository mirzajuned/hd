class UserNotesController < ApplicationController
  before_action :set_user_note, only: [:show, :edit, :update, :destroy]

  def new
    @patient_id = params[:patientid]
    @doctor_id = params[:doctor_id]
    @type = params[:type]

    if !params[:template_details].nil?
      @template_details = params[:template_details]
      @template_details = JSON.parse(@template_details)

      # puts medical_body = @template_details["medical_body"].(gsub("%p_name%",Patient.find(@patientid).fullname)).(gsub("%p_age%",Patient.find(@patientid).age)).(gsub("%p_dob%",Patient.find(@patientid).dob)).(gsub("%p_gender%",Patient.find(@patientid).gender)).(gsub("%p_mobile%",Patient.find(@patientid).mobilenumber)).(gsub("%d_name%",User.find(@doctor_id).fullname))

      @opdrecord = OpdRecord.where(patientid: @patient_id)
      @opdrecord_last = if @opdrecord.count > 0
                          @opdrecord.order(created_at: :desc)[0]
                        else
                          ''
                        end

      if @opdrecord_last == ''
        @diagnosis = ''
        @procedure = ''
      else
        if @opdrecord_last.templatetype != 'freeform'
          # Diagnosis
          @diagnosis = ''
          get_diagnosis

          # Procedure
          @procedure = ''
          if @opdrecord_last.procedure.count > 0
            @opdrecord_last.procedure.each do |procedure|
              @procedure = procedure.procedurename.to_s + ',' + @opdrecord_last.get_label_for_procedure_side(procedure.procedureside).to_s + ' | ' + @procedure
            end
          end
        else
          @diagnosis = @opdrecord_last.diagnosis
        end
      end

      @patient = Patient.find(@patient_id)

      @initial_referral_type = PatientReferralType.includes(:referral_type, :sub_referral_type).where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]

      @ref_doc_name = if @initial_referral_type.present?
                        if @initial_referral_type.referral_type_id == 'FS-RT-0002'
                          @initial_referral_type.try(:sub_referral_type).try(:name)
                        else
                          '%ref_doc%'
                        end
                      else
                        ''
                      end
      medical_body = @template_details['medical_body'].gsub('%p_name%', @patient.fullname.to_s).gsub('%p_age%', @patient.try(:age).to_s).gsub('%p_gender%', @patient.try(:gender).to_s).gsub('%p_dob%', @patient.try(:dob).to_s).gsub('%p_mobile%', @patient.try(:mobilenumber).to_s).gsub('%d_name%', User.find(@doctor_id).try(:fullname).to_s).gsub('%ref_doc%', @ref_doc_name)

      # .gsub("%p_diagnosis%",@diagnosis).gsub("%p_procedure%",@procedure)

      @template_details['medical_body'] = medical_body
      @user_note = UserNote.new(@template_details)
    else
      @user_note = UserNote.new
    end

    respond_to do |format|
      format.js {}
    end
  end

  def edit
    @user_note = UserNote.find(params[:id])
    @patient_id = @user_note.patient_id
    @doctor_id =  @user_note.doctor
    respond_to do |format|
      format.js {}
    end
  end

  def create
    @user_note = UserNote.new(user_note_params)
    respond_to do |format|
      if @user_note.save
        @user_notes_templates = UserNotesTemplate.where(
          organisation_id: current_facility.organisation_id.to_s, :specialty_id.in => current_user.specialty_ids,
          is_deleted: false, '$or' => [{ facility_id: current_facility.id.to_s, level: 'facility' },
                                       { user_id: current_user.id, level: 'user' }, { level: 'organisation' }]
        ).order(level: :DESC)
        @patient = Patient.find(@user_note.patient_id)
        @doctor = @user_note.doctor
        @user_note_doctor = User.find_by(id: @user_note.doctor)
        @patient_certificates = UserNote.where(patient_id: @patient.id)
        format.js {}
      else
        format.js { render action: 'new' }
        format.json { render json: @user_note.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @user_note.update(user_note_params)
        @user_notes_templates = UserNotesTemplate.where(
          organisation_id: current_facility.organisation_id.to_s, :specialty_id.in => current_user.specialty_ids,
          is_deleted: false, '$or' => [{ facility_id: current_facility.id.to_s, level: 'facility' },
                                       { user_id: current_user.id, level: 'user' }, { level: 'organisation' }]
        ).order(level: :DESC)
        @patient = Patient.find(@user_note.patient_id)
        @doctor = @user_note.doctor
        @user_note_doctor = User.find_by(id: @user_note.doctor)
        @patient_certificates = UserNote.where(patient_id: @patient.id)
        format.js {}
      else
        format.html { render action: 'edit' }
        format.json { render json: @user_note.errors, status: :unprocessable_entity }
      end
    end
  end

  # nandish: This method not being used.
  # def destroy
  #   @user_note.destroy
  #   respond_to do |format|
  #     format.html { redirect_to medical_certificates_url }
  #     format.json { head :no_content }
  #   end
  # end

  def print
    @user_note = UserNote.find(params[:id])
    @organisation = current_user.organisation
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @user_note_doctor = User.find_by(id: @user_note.doctor)
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    if params[:pagesize] == 'A4'
      respond_to do |format|
        format.pdf { render template: 'user_notes/printcertificate.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
      end
    elsif params[:pagesize] == 'A5'
      respond_to do |format|
        format.pdf { render template: 'user_notes/printcertificate_a5.pdf.erb', pdf: 'xyz', layout: 'pdfgen_invoice.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' } }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user_note
    @user_note = UserNote.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_note_params
    params[:user_note].permit(:medical_subject, :date_of_issue, :date_from, :date_to, :medical_body, :patient_id, :user_id, :doctor, :category, :type)
  end

  def get_diagnosis
    @opdrecord_last.diagnosislist.each do |diagnosis|
      diagnosis_output = if diagnosis.created_from == 'migration'
                           diagnosis.diagnosisname.capitalize
                         else
                           diagnosis.diagnosisoriginalname.capitalize
                         end
      @diagnosis = diagnosis_output + ' | ' + @diagnosis
    end
  end
end
