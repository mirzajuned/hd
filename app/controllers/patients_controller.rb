require 'date'
require 'time'
class PatientsController < ApplicationController
  before_action :authorize
  before_action :patient_type, only: [:new, :edit]
  before_action :details_view_params, only: [:patient_details]
  respond_to :js, :json, :html
  layout 'loggedin'

  def new
    @modal = ('#free-invoice-inventory-modal' if params[:store_id].present?) || '#patient-modal'
    @patient = Patient.new
    @area_details = ['', '']
    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  end

  def create
    @patient = Patients::CreateService.call(params, current_user, current_facility) # Call Patient CreateService
    if params[:store_id].present?
      @store_id = params[:store_id]
      @url = '/invoice/inventory_orders/new'
    end
  end

  def edit
    @patient = Patient.find_by(id: params[:id])
    @patient_location = if @patient.try(:location_id).present?
                          Location.find_by(id: @patient.try(:location_id))
                        elsif @patient.pincode.present?
                          Location.find_by(pincode: @patient.try(:pincode), country_id: @patient.try(:country_id))
                        end
    
    @area_details = ['', '']
    if @patient_location.present?
      @area_details = @patient_location.area_managers.pluck(:area_name, :_id)
    end
    @occupation_list = Global.send('occupation_list').send('sets').pluck(:name, :snomedcode)
    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  end

  def update
    @patient = Patients::UpdateService.call(params[:id], params, current_user) # Call Patient UpdateService
    @past_appointment = AppointmentListView.where(patient_id: params[:id], :appointment_date.lt => Date.current, :current_state.nin => ['Deleted', 'Scheduled']).order(appointment_date: :desc)
    @workflow = OpdClinicalWorkflow.find_by(patient_id: params[:id])
    QueueManagementJobs::WorkflowJob.perform_later(@workflow.id.to_s, @workflow.facility_id.to_s) if @workflow.present?
    # InvoiceJobs::PatientUpdateJob.perform_later(@patient.id.to_s)
  end

  def destroy
    @patient = Patient.find(params[:id])
    respond_to do |format|
      format.js {} if @patient.destroy
    end
  end

  def patient_management
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    @active_tab = params[:active_tab]
    # specialty = if params[:specialty_id] == 'all_specialties'
    #               @available_specialties.pluck(:id)
    #             else
    #               [params[:specialty_id]]
    #             end

    @patients_list = Patient.where(reg_date: @current_date, reg_facility_id: current_facility.id.to_s,
                                   reg_hosp_ids: [current_user.organisation_id.to_s], reg_status: true, opd_visit_count: 0)
  end

  def patient_details
    respond_to do |format|
      format.js { render 'patients/patient_details' } # List
      format.html { render 'patients/patient_details', layout: false } # Calendar
    end
  end

  # search in list view
  def search_patient_lists
    if params[:q].present?
      @patient_list = Patient.where(reg_date: params[:current_date], reg_facility_id: current_facility.id.to_s,
                                    :fullname => /#{Regexp.escape(params[:q])}/i).order('reg_time ASC').limit(15)
    end

    respond_to do |format|
      format.json { render 'patients/search_patient_lists' }
    end
  end

  def download
    @asset = Patientasset.find_by(patient_id: params[:patient_id])
    file_url = @asset.asset_path_url
    filename = file_url.split('/').last
    if Rails.env == 'development'
      send_file(
        @asset.asset_path.current_path,
        filename: filename,
        type: @asset.content_type
      )
    else
      IO.copy_stream(open(file_url), Rails.root.to_s + '/public/uploads/tmp/' + filename)
      send_file(
        Rails.root.to_s + '/public/uploads/tmp/' + filename,
        filename: filename,
        type: @asset.content_type
      )
    end
  end

  # Search Patient Before Creating Appointment/Admission/Ot
  def search
    @store_id = params[:store_id] # Inventory Case
    @date = params[:current_date] || Date.current.strftime('%d/%m/%Y')
    @time = params[:current_time] || Time.current.strftime('%I:%M %p')
    @type = params[:type]
    @url = params[:url]
    @url_store = params[:url_store] # Inventory Case
    @modal = '#' + params[:modal].to_s
    @facilities = Facility.where(organisation_id: current_organisation['_id'])
    @camps = Camp.where(organisation_id: current_organisation['_id'])
  end

  # Search Patient Before Viewing summary

  def search_patient_summary
    @modal = '#' + params[:modal].to_s
  end

  # Search Patient Results
  def search_patient
    r_query = params[:search].split(' ').join('.*')
    @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, search: /#{r_query}/i).limit(8).pluck(:patient_id, :patient_name, :mobile_number, :patient_identifier_id, :mr_no)
    render json: @patientlist.to_json
  end

  def search_patient_mr_no
    r_query = params[:search]
    # @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, mr_no_search: /^#{r_query}/).limit(8)
    begin
      @patientlist = PatientSearch.search r_query, fields: [:mr_no_search], match: :word_middle, limit: 10,
                                                   misspellings: { below: 0 }, order: { _score: :desc },
                                                   where: { reg_hosp_ids: current_user.organisation_id.to_s }
    end

    # if @patientlist.blank? # fallback on db
    #   @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, mr_no_search: /^#{r_query}/).limit(8)
    # end

    render json: @patientlist.pluck(:patient_id, :patient_name, :mobile_number, :patient_identifier_id, :mr_no).to_json
    @facility = Facility.find_by(id: current_facility.id)
    @facility.set(search_type: params[:search_type])
  end

  def search_patient_mobile_no
    r_query = params[:search].delete(' ')
    # @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, mobile_number: r_query.to_i).limit(8)

    begin
      @patientlist = PatientSearch.search r_query.to_i, fields: [:mobile_number], limit: 25, misspellings: { below: 5 },
                                                        where: { reg_hosp_ids: current_user.organisation_id.to_s }
    end

    # if @patientlist.blank? # fallback on db
    #   @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, mobile_number: r_query.to_i).limit(8)
    # end

    render json: @patientlist.pluck(:patient_id, :patient_name, :mobile_number, :patient_identifier_id, :mr_no).to_json
    @facility = Facility.find_by(id: current_facility.id)
    @facility.set(search_type: params[:search_type])
  end

  def search_patient_name
    r_query = params[:search]
    # @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, patient_name_search: /^#{r_query}/).limit(8)
    # @patientlist = PatientSearch.search r_query, fields: [:patient_name_search], match: :word_middle, operator: "or", limit: 50, misspellings: {below: 5}, order: { _score: :desc }, where: {reg_hosp_ids: current_user.organisation_id.to_s}, load: false
    begin
      @patientlist = PatientSearch.search r_query, fields: [:patient_name_search], match: :word_middle, operator: 'or',
                                                   limit: 50, misspellings: { below: 5 }, order: { _score: :desc },
                                                   where: { reg_hosp_ids: current_user.organisation_id.to_s }
    end
    # if @patientlist.blank? # fallback on db
    #   @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, patient_name_search: /^#{r_query}/).limit(8)
    # end

    render json: @patientlist.pluck(:patient_id, :patient_name, :mobile_number, :patient_identifier_id, :mr_no).to_json
    @facility = Facility.find_by(id: current_facility.id)
    @facility.set(search_type: params[:search_type])
  end

  def search_patient_identifier
    r_query = params[:search].delete(' ').try(:downcase)
    # @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, patient_identifier_id_search: /^#{r_query}/).limit(8)
    begin
      @patientlist = PatientSearch.search r_query, fields: [:patient_identifier_id], match: :word_middle, operator: 'or',
                                                   limit: 10, misspellings: { below: 0 }, order: { _score: :desc },
                                                   where: { reg_hosp_ids: current_user.organisation_id.to_s }
    end
    # if @patientlist.blank? # fallback on db
    #   @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, patient_identifier_id_search: /^#{r_query}/).limit(8)
    # end

    render json: @patientlist.pluck(:patient_id, :patient_name, :mobile_number, :patient_identifier_id, :mr_no).to_json
    @facility = Facility.find_by(id: current_facility.id)
    @facility.set(search_type: params[:search_type])
  end

  # def search_patient
  #   r_query = params[:search].split(" ").join("")
  #
  #   Rails.logger.info("========================r_query===========#{r_query}")
  #   if params[:search_filter] == "MR No"
  #     # @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, mr_no_search: /#{r_query}/i).limit(8)
  #     @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, mr_no_search: /^#{r_query}/).limit(8)
  #   elsif params[:search_filter] == "Mobile No."
  #     @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, mobile_number: r_query.to_i).limit(8)
  #   elsif params[:search_filter] == "Name"
  #     @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, patient_name: /^#{r_query}/).limit(8)
  #   elsif params[:search_filter] == "Patient ID"
  #     @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, patient_identifier_id_search: /^#{r_query}/).limit(8)
  #   end
  #   render :json =>  @patientlist.pluck(:patient_id, :patient_name, :mobile_number, :patient_identifier_id, :mr_no).to_json
  # end

  # Validate Uniqueness of MRN
  def check_mrn
    existing_mrn = params[:existing_mrn]
    mr_no = params[:patient_other_identifier][:mr_no].to_s.strip.upcase

    if existing_mrn != mr_no
      @poi = PatientOtherIdentifier.find_by(organisation_id: current_user.organisation_id, mr_no: mr_no)
    end

    respond_to do |format|
      format.json { render json: !@poi.present? }
    end
  end

  def downloadpatientsummary
    respond_to do |format|
      format.html
      format.pdf do
        render template: 'patients/downloadpatientsummary', pdf: 'report', layout: 'pdfgen', disposition: 'attachment'
      end
    end
  end

  def summary # Method Not in Use
    # @patient_summary_timeline = PatientSummaryTimeline.all
    @department_id = current_user.department_id
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
    @patient = Patient.find(params[:patientid])
    # patient_org_id = PatientIdentifier.find_by(patient_id: @patient.id).try(:patient_org_id)
    # @qr = RQRCode::QRCode.new(patient_org_id+":"+@patient.fullname+","+@patient.mobilenumber).to_img.resize(200, 200).to_data_url
    @section = params[:opd]
    # Rails.logger.info("=============================================#{@section}")

    if @section == '440655000'
      @appointment = Appointment.find(params[:appointment_id])
      @patient_pastappointments = Appointment.where(patient_id: params[:patientid]).order(appointmentdate: :asc, appointmenttime: :asc).limit(3)
      @patient_pastinvoices = Invoice::Opd.where(patient_id: params[:patientid])
      @doctor = @appointment.consultant_id.to_s
      # @docremindernote = DocReminderNote.find_by(patient_id: params[:patientid].to_s)
      # if @docremindernote.present?
      #   @reminder_text = @docremindernote.reminder_text
      # else
      #   @reminder_text = ""
      # end
      ########################################### code for one day one template
      # OpdRecord.where(appointmentid: params[:appointment_id].to_s).each do|opdrecord|
      #   if opdrecord.templatetype == "express"
      #     @express_template = "express"
      #   end
      #   if opdrecord.templatetype == "eye"
      #     @eye_template = "eye"
      #   end
      #   if opdrecord.templatetype == "quickeye"
      #     @quickeye_template = "quickeye"
      #   end
      #   if opdrecord.templatetype == "optometrist"
      #     @opto_template = "optometrist"
      #   end
      #   if opdrecord.templatetype == "freeform"
      #     @freefrom_template = "freeform"
      #   end
      #   if opdrecord.templatetype == "knee"
      #     @knee_template = "knee"
      #   end
      #   if opdrecord.templatetype == "shoulder"
      #     @shoulder_template = "shoulder"
      #   end
      #   if opdrecord.templatetype == "spine"
      #     @spine_template = "spine"
      #   end
      #   if opdrecord.templatetype == "hip"
      #     @hip_template = "hip"
      #   end
      #   if opdrecord.templatetype == "footankle"
      #     @footankle_template = "footankle"
      #   end
      #   if opdrecord.templatetype == "wristhand"
      #     @wristhand_template = "wristhand"
      #   end
      #   if opdrecord.templatetype == "footankle"
      #     @footankle_template = "footankle"
      #   end
      #   if opdrecord.templatetype == "elbow"
      #     @elbow_template = "elbow"
      #   end
      #   if opdrecord.templatetype == "trauma"
      #     @trauma_template = "trauma"
      #   end
      # end

      # #############################################3

    elsif @section == '440654001'
      @admission = Admission.find(params[:admission_id])
      @patient_pastinvoices = Invoice::Ipd.where(patient_id: params[:patientid])
      @doctor = @admission.doctor.to_s
      # if DocReminderNote.find_by(patient_id: @admission.patient.id.to_s) == nil
      #   @reminder_text = ""
      # else
      #   @reminder_text = DocReminderNote.find_by(patient_id: @admission.patient.id.to_s).reminder_text
      # end
      @clinical_note = Inpatient::IpdRecord::ClinicalNote.find_by(admission_id: @admission.id)
      @operative_note = Inpatient::IpdRecord::OperativeNote.find_by(admission_id: @admission.id)
      @discharge_note = Inpatient::IpdRecord::DischargeNote.find_by(admission_id: @admission.id)
    end

    @invoice_templates = InvoiceTemplate.where(user_id: current_user.id)
    @certificate_templates = UserNotesTemplate.where(organisation_id: current_user.organisation_id).order(level: :desc)
    # @opdrecords = OpdRecordAttribute.where(:patient_id => params[:patientid]).to_a
    @assetuploads = PatientSummaryAssetUpload.where(:id.in => ['560cc6f72b2e26135d000000', '560cc6f72b2e26135d000001', '560cc6f72b2e26135d000002', '560cc6f72b2e26135d000003'], is_deleted: false)
    @patient_uploads = @patientfiles = PatientSummaryAssetUpload.where(patient_id: @patient.id, is_deleted: false).order(reported_date: :desc)
    # @custom_templates = UsersOpdRecord.where(:user_id => @appointment.user_id)
    @patient_timelines = PatientTimeline.where(patient_id: params[:patientid]).order_by(encounterdate: 'desc')
    @patient_prescriptions = PatientPrescription.where(patient_id: params[:patientid]).order_by(encounterdate: 'desc')
    @patient_investigations = PatientOphthalAssessment.where(patient_id: params[:patientid])
    @radiology_investigations = PatientRadiologyAssessment.where(patient_id: params[:patientid])
    @patient_legacy_clinicalnote = LegacyOpdClinicalNote.where(new_patient_id: params[:patientid])
    @patient_legacy_surgerynote = LegacyIpdClinicalNote.where(new_patient_id: params[:patientid])
    @patient_legacy_prescription = LegacyPrescription.where(new_patient_id: params[:patientid])
    @patient_legacy_appointment = LegacyAppointment.where(new_patient_id: params[:patientid])
    @patient_legacy = LegacyPatient.find_by(new_patient_id: params[:patientid],
                                            organisation_id: current_user.organisation_id.to_s)

    @eyedrop_allergy = []
    @patient_allergy_eye_drops = @patient.patient_history.patientallergyhistory.eyedrops
    @patient_allergy_eye_drops&.each do |eyedrops|
      @eyedrop_allergy.push(@patient.get_label_for_allergy('eyedrops', eyedrops))
    end
    if @appointment
      if @appointment.dilation_start_time
        @dilation_time_difference = TimeDifference.between(@appointment.dilation_start_time + 60.minutes, Time.current).in_minutes
      else
        @dilation_time_difference = 100
      end
    end
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  # def save_doc_reminder_note

  #   if DocReminderNote.find_by(patient_id: params[:patient_id]) == nil
  #     @reminder_note = DocReminderNote.new(reminder_text: params[:reminder_text], patient_id: params[:patient_id] )
  #     @reminder_note.save
  #   else
  #     @reminder_note = DocReminderNote.find_by(patient_id: params[:patient_id])
  #     @reminder_note.update(reminder_text: params[:reminder_text])
  #   end
  #   # respond_to do |format|
  #   #   format.html{ render nothing: true }
  #   # end
  #   render json: {"reminder_note": @reminder_note.reminder_text}
  # end

  def render_timeline
    @patient_timelines = PatientTimeline.where(patient_id: params[:ajax][:patientid])
    respond_to do |format|
      format.html { render partial: 'patients/partials/patient_summary_timeline_tbody.html', layout: false }
    end
  end

  #
  def load_new_timelines # Method Not in Use
    @department_id = current_user.department_id
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
    @patient_timelines = PatientTimeline.where(patient_id: params[:patient_id]).order_by('encounterdate desc')
    @patient_prescriptions = PatientPrescription.where(patient_id: params[:patient_id])
    @appointment = Appointment.find(params[:appointment_id]) if params[:appointment_id].present?
    respond_to do |format|
      format.html { render partial: 'patients/partials/patient_summary_timeline_tbody.html', layout: false }
    end
  end

  def load_new_prescriptions
    @patient_prescriptions = PatientPrescription.where(patient_id: params[:patient_id]).order_by('created_at desc')
    # puts "Found #{@patient_prescriptions.count} prescriptions."
    respond_to do |format|
      format.html { render partial: 'patients/partials/patient_summary_prescriptions_tbody.html', layout: false }
    end
  end

  def load_new_legacyclinicalnote
    @patient_legacy_clinicalnote = LegacyOpdClinicalNote.where(new_patient_id: params[:patient_id])
    respond_to do |format|
      format.html { render partial: 'patients/partials/patient_legacy_summary_tbody.html', layout: false }
    end
  end

  def load_new_legacyprescription
    @patient_legacy_prescription = LegacyPrescription.where(new_patient_id: params[:patient_id])
    respond_to do |format|
      format.html { render partial: 'patients/partials/patient_legacy_prescription_tbody.html', layout: false }
    end
  end

  def load_new_legacysurgerynote
    @patient_legacy_surgerynote = LegacyIpdClinicalNote.where(new_patient_id: params[:patient_id])
    respond_to do |format|
      format.html { render partial: 'patients/partials/patient_legacy_surgery_tbody.html', layout: false }
    end
  end

  def load_new_assets
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:patient_id], is_deleted: false)
    ## puts "counting patient files #{@patient_files.count}"
    ## puts "1111111111111111"
    respond_to do |format|
      format.html { render partial: 'patients/display_all_patient_asset', layout: false }
      # format.json {render json: @patietn_files.as_json }
    end
  end

  def load_new_investigations
    @patient = Patient.find(params['patient_id'])
    @patient_investigations = PatientOphthalAssessment.where(patient_id: params['patient_id'])
    @radiology_investigations = PatientRadiologyAssessment.where(patient_id: params['patient_id'])
    ## puts "counting patient files #{@patient_files.count}"
    ## puts "1111111111111111"
    respond_to do |format|
      format.html { render partial: 'patients/display_patient_all_ivestigations', layout: false }
      # format.json {render json: @patietn_files.as_json }
    end
  end

  def signup
    dob = "#{params[:patientdobday]}/#{params[:patientdobmonth]}/#{params[:patientdobyear]}"
    smsmobilenumber = "#{params[:patientmobilenumberhidden]}#{params[:patientmobilenumber]}"
    @patient = Patient.create!(fullname: params[:patientname], gender: params[:patientgender], displayage: params[:patientage], age: params[:patientage], patientdobday: params[:patientdobday], patientdobmonth: params[:patientdobmonth], patientdobyear: params[:patientdobyear], dob: dob, smsmobilenumber: smsmobilenumber,
                               mobilenumber: params[:patientmobilenumber], email: params[:patientemailaddress])
    if @patient
      @appointment = Appointment.create!(appointmentdate: params[:appointmentdate], appointmenttime: params[:appointmenttime], visittype: params[:visittype], patient_id: @patient.id, departmenttype: params[:departmenttype], appointmentstatus: 416774000)
    end
    @datepicker_date = Date.strptime(params[:appointmentdate], '%d/%m/%Y').strftime('%Y-%m-%d').to_s
    @appointmntlist = Appointment.where(appointmentdate: Date.strptime(params[:appointmentdate], '%d/%m/%Y').strftime('%Y-%m-%d')).order(appointmenttime: :desc)
    @appointmentpastlist = Appointment.where("patient_id = '#{@patient.id}' AND appointmentdate < '#{Date.current.strftime('%Y-%m-%d')}'").order(appointmenttime: :desc).limit(2)
    respond_to do |format|
      format.js {}
    end
  end

  # Brakeman :: cannot find anywhere in the view, so commenting #reverted
  # add for templates tree structure
  def templatestree
    @treeids = Global.orthopedics.send((params[:template][:treeid]).to_s)
    respond_to do |format|
      @patientfiles = PatientSummaryAssetUpload.where(patient_id: @patient.id, is_deleted: false).order(reported_date: :desc)
      format.js { render 'templatestree', layout: false }
    end
  end

  def details
    @patient = Patient.find(params[:patient_id])

    # Added Huzi For Refresh Purpose in Ipd Patients
    @current_date = params[:current_date]
    respond_to do |format|
      format.js { render 'details', layout: false }
      format.html { render layout: false }
    end
  end

  def basic_details
    @appointment = Appointment.find(params[:appointment_id])
    @patient = @appointment.patient
    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def patient_comments
    @appointment = Appointment.find(params[:appointment_id])
    @notes = PatientRecordNote.new
    @save_path = 'patients_save_comments_path'
    respond_to do |format|
      format.js { render 'patients/patient_notes/patient_comment.js.erb', layout: false }
    end
  end

  def edit_patient_comments
    @appointment = Appointment.find(params[:appointment_id])
    @notes = PatientRecordNote.find_by(patient_id: @appointment.patient_id.to_s, user_id: @appointment.user_id.to_s)
    @user = User.find(@appointment.user_id)
    @save_path = 'patients_update_patient_comments_path'
    respond_to do |format|
      format.js { render 'patients/patient_notes/patient_comment.js.erb', layout: false }
    end
  end

  def save_comments
    @appointment = Appointment.find(params[:record_note][:appointment_id])
    @save_path = 'patients_update_patient_comments_path'
    @user = User.find(@appointment.user_id)
    params.require(:record_note).permit!
    @notes = PatientRecordNote.create(params.require(:record_note).permit(:patient_id, :appointment_id, :user_id, :common_note))
    note1 = {}
    params[:record_note][:common_note_attributes].each do |_key, value|
      note1[:comment] = value[:comment]
      note1[:comment_by] = current_user.id
      note1[:time] = value[:time]
    end
    arr = []
    arr.push(note1)
    @notes.update_attributes(common_note: arr)
    respond_to do |format|
      format.js { render 'patients/patient_notes/patient_comment_update.js.erb', layout: false }
    end
  end

  def update_patient_comments
    @appointment = Appointment.find(params[:record_note][:appointment_id])
    @save_path = 'patients_update_patient_comments_path'
    @user = User.find(@appointment.user_id)
    params.require(:record_note).permit!
    @notes = PatientRecordNote.find_by(patient_id: params[:record_note][:patient_id])
    @notes.common_note.delete_all
    @notes.update_attributes(common_note: params[:record_note][:common_note_attributes])
    respond_to do |format|
      format.js { render 'patients/patient_notes/patient_comment_update.js.erb', layout: false }
    end
  end

  def destroy_patient_notes
    @save_path = 'patients_update_patient_comments_path'
    @appointment = Appointment.find(params[:appointment_id])
    @user = User.find(@appointment.user_id)
    @notes = PatientRecordNote.find(params[:notes_id])
    @notes.common_note.find(params[:note_id]).delete
    respond_to do |format|
      format.js { render 'patients/patient_notes/patient_comment_update.js.erb', layout: false }
    end
  end

  # not used, delete
  def edit_patient_history
    @templatetype = params[:templatetype]
    @patient = Patient.find(params[:patientid])
    @templateid = TemplatesHelper.get_template_id_for_patienthistory_template(@templatetype)
    @formbuttons = Global.ehrcommon.newepisode.formbuttons
    @savepath = Global.ehrcommon.patienthistory.savepath
    @patienthistory = PatientHistory.new
    @patienthistory.initialize_nested_objects
    respond_to do |format|
      format.html {}
      format.js { render 'patients/edit_pparams.require(:patient).permit(:fullname, :gender,:dob, :age, :mobilenumber,:email, :blood_group,:address_1,:address_2,:city,:state,:pincode,:emergencycontactname, :emergencymobilenumber, :maritalstatus, :specialstatus, :occupation, patientassets_attributes: [:asset_path],patient_history_attributes: [ :patient_id, :patientid, :templatetype, :templateid, patientpersonalhistory_attributes: [problems: [] ], patientallergyhistory_attributes: [:others, antimicrobialagents: [], antifungalagents: [], antiviralagents: [], contact: [], food: [] ] ])atient_history', layout: false }
    end
  end

  def edit_patient_details
    @templatetype = params[:templatetype]
    @patient = Patient.find_by(id: params[:patientid])
    @templateid = TemplatesHelper.get_template_id_for_patienthistory_template(@templatetype)
    @formbuttons = Global.ehrcommon.patientregistered.formbuttons
    @savepath = Global.ehrcommon.patientregistered.savepath
    @patient.build_patient_history.initialize_nested_objects if @patient.patient_history.nil?
    respond_to do |format|
      format.html {}
      format.js { render 'patients/edit_patient_history', layout: false }
    end
  end

  def save_patient_history
    @patient = Patient.find_by(id: params[:patient][:patientid])
    if @patient.update_attributes(add_patient_history_params)
      respond_to do |format|
        format.js { render 'patients/save_patient_history', layout: false }
      end
    end
  end

  def load_patient_summary_asset
    patientsummaryuploads = PatientSummaryAssetUpload.where(patient_id: params[:patientid], is_deleted: false)
    @patientfiles = Array[]
    counter = 0
    patientsummaryuploads.each do |upload|
      if upload.path_ids[0].to_s == params[:folder_id].to_s
        @patientfiles[counter] = upload
        counter += 1
      end
    end
    respond_to do |format|
      format.js { render 'patients/load_patient_summary_asset', layout: false }
    end
  end

  def display_prescriptions
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:ajax][:patientid], parent_folder_id: '560cc6f72b2e26135d000000', is_deleted: false)
    respond_to do |format|
      format.js { render 'patients/display_prescriptions', layout: false }
    end
  end

  def display_radiology
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:ajax][:patientid], parent_folder_id: '560cc6f72b2e26135d000001', is_deleted: false)
    respond_to do |format|
      format.js { render 'patients/display_radiology', layout: false }
    end
  end

  def display_laboratory
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:ajax][:patientid], parent_folder_id: '560cc6f72b2e26135d000002', is_deleted: false)
    respond_to do |format|
      format.js { render 'patients/display_laboratory', layout: false }
    end
  end

  def display_otherreports
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:ajax][:patientid], parent_folder_id: '560cc6f72b2e26135d000003', is_deleted: false)
    respond_to do |format|
      format.js { render 'patients/display_otherreports', layout: false }
    end
  end

  def display_insurancefiles
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:ajax][:patientid], parent_folder_id: '560cc6f72b2e26135d000004', is_deleted: false)
    respond_to do |format|
      format.js { render 'patients/display_insurancefiles', layout: false }
    end
  end

  def display_opdreports
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:ajax][:patientid], parent_folder_id: '560cc6f72b2e26135d000005', is_deleted: false)
    respond_to do |format|
      format.js { render 'patients/display_opdreports', layout: false }
    end
  end

  def display_ipdreports
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:ajax][:patientid], parent_folder_id: '560cc6f72b2e26135d000006', is_deleted: false)
    respond_to do |format|
      format.js { render 'patients/display_ipdreports', layout: false }
    end
  end

  def display_drawings
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:ajax][:patientid], parent_folder_id: '560cc6f72b2e26135d000007', is_deleted: false)
    respond_to do |format|
      format.js { render 'patients/display_drawings', layout: false }
    end
  end

  def display_ophthal
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: params[:ajax][:patientid], parent_folder_id: '560cc6f72b2e26135d000008', is_deleted: false).order('name ASC')
    respond_to do |format|
      format.js { render 'patients/display_ophthal', layout: false }
    end
  end

  def load_patient_summary_root_asset
    @breadcrumblinks = PatientSummaryAssetUpload.find_by(:id.in => ['560cc6f72b2e26135d000000', '560cc6f72b2e26135d000001', '560cc6f72b2e26135d000002', '560cc6f72b2e26135d000003']).ancestors
    @assetuploads = PatientSummaryAssetUpload.where(:id.in => ['560cc6f72b2e26135d000000', '560cc6f72b2e26135d000001', '560cc6f72b2e26135d000002', '560cc6f72b2e26135d000003'], is_deleted: false)
    respond_to do |format|
      format.js { render 'patients/load_patient_summary_root_asset', layout: false }
    end
  end

  def view_patient_file; end

  def view_prescription
    if !params[:opdrecordid].nil? && !params[:appointmentid].nil?
      @opdrecord = OpdRecord.find(params[:opdrecordid])
      @appointment = Appointment.find(params[:appointmentid])
    elsif !params[:ipdrecordid].nil? && !params[:admissionid].nil?
      @ipdrecord = Inpatient::IpdRecord.find(params[:ipdrecordid])
      @admission = Admission.find(params[:admissionid])
    end

    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    # puts params[:opdrecorddate]  #fix this.
    respond_to do |format|
      format.js { render 'view_prescription', layout: false }
    end
  end

  def view_ipd_summary # Method not in Use
    @ipdrecord = IpdRecord.find_by(id: params[:ipdrecordid])
    @patient = Patient.find_by(id: params[:patientid])
    # @ipdcomments = @ipdrecord.opd_record_comments
    @admission = Admission.find_by(id: params[:admission])
    # @speciality_folder_name = params[:specality]
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
    @templatetype = params[:templatetype]
    @users = User.where(:department_id => current_user.department_id, :facility_ids.in => [@admission.facility_id])
    respond_to do |format|
      format.js { render 'templates/save_ipd_record', layout: false }
    end
  end

  def new_folder
    @patient = Patient.find_by(id: params[:patientid])
    @patientsummaryassetupload = PatientSummaryAssetUpload.new
    respond_to do |format|
      format.js { render 'new_folder', layout: false }
    end
  end

  def create_folder
    @patient = Patient.find_by(id: params[:patient_summary_asset_upload][:patient_id])
    @patientsummaryassetupload = PatientSummaryAssetUpload.new(create_patient_summary_asset_upload)
    respond_to do |format|
      if @patientsummaryassetupload.save
        format.js { render 'create_folder', layout: false }
      else
        format.js { render 'new_folder', layout: false }
      end
    end
  end

  # def edit_folder_name
  # end

  # def rename_folder_name
  # end

  # def delete_folder
  # end

  # def upload_files
  # end

  # def rename_filename
  # end

  # def save_uploaded_files
  # end

  # def move_files
  # end

  # def add_tags_to_file
  # end

  # def add_tags_to_files
  # end

  # def search_files_by_tags
  # end

  # def search_files_by_name
  # end

  def patientsearchresult # Method not in use
    @patient = Patient.find_by(id: params['patient_id'])
    @patient_uploads = PatientSummaryAssetUpload.where(patient_id: @patient.try(:id), is_deleted: false).order(reported_date: :desc)
    @organisation_user = current_user.organisation.users.pluck(:id)
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
    @patient_timelines = PatientTimeline.where(patient_id: @patient.id, :user_id.in => @organisation_user)
    @patient_prescriptions = PatientPrescription.where(patient_id: @patient.id, :user_id.in => @organisation_user)
    @patientfiles = PatientSummaryAssetUpload.where(patient_id: @patient.id, is_deleted: false).order(reported_date: :desc)
    @patient_legacy_clinicalnote = LegacyOpdClinicalNote.where(new_patient_id: params['patient_id'])
    @patient_legacy_prescription = LegacyPrescription.where(new_patient_id: params['patient_id'])
    @patient_legacy_surgerynote = LegacyIpdClinicalNote.where(new_patient_id: params['patient_id'])
    @patient_investigations = PatientOphthalAssessment.where(patient_id: params['patientid'])
    @radiology_investigations = PatientRadiologyAssessment.where(patient_id: params['patientid'])
    # if DocReminderNote.find_by(patient_id: params["patient_id"].to_s) == nil
    #   @reminder_text = ""
    # else
    #   @reminder_text = DocReminderNote.find_by(patient_id: params["patient_id"].to_s).reminder_text
    # end
    respond_to do |format|
      format.js
      format.html
    end
  end

  def searchsetupforsummary
    @patient = Patient.find_by(id: params['patient_id'], :reg_hosp_ids.in => [current_user.organisation_id.to_s])
    @organisation_user = current_user.organisation.users.pluck(:id)
    patient_type = []
    @appointment = Appointment.find_by(patient_id: @patient.id, appointmentdate: Date.current, :user_id.in => @organisation_user)
    if @appointment
      @appointment_id = @appointment.id
      patient_type << @appointment_id
    else
      patient_type << 'null'
    end

    @admission = Admission.find_by(patient_id: @patient.id, admissiondate: Date.current, :user_id.in => @organisation_user)
    if @admission
      @admission_id = @admission.id
      patient_type << @admission_id
    else
      patient_type << 'null'
    end

    respond_to do |format|
      format.json { render json: patient_type }
    end
  end

  def preview_patient_excel
    respond_to do |format|
      format.js
    end
  end

  def download_patient_excel
    my_facilities = current_user.organisation.facility_ids
    if (params[:facility_id] == '') && (params[:doctor_id] == '')
      @appointments = Appointment.where(:facility_id.in => my_facilities, appointmentdate: params[:start_date].to_date..params[:end_date].to_date, :appointmentstatus.nin => [89925002])
    elsif (params[:facility_id] == '') &&  (params[:doctor_id] != '')
      @appointments = Appointment.where(:facility_id.in => my_facilities, appointmentdate: params[:start_date].to_date..params[:end_date].to_date, consultant_id: params[:doctor_id], :appointmentstatus.nin => [89925002])
    elsif (params[:facility_id] != '') &&  (params[:doctor_id] == '')
      @appointments = Appointment.where(:facility_id.in => my_facilities, appointmentdate: params[:start_date].to_date..params[:end_date].to_date, facility_id: params[:facility_id], :appointmentstatus.nin => [89925002])
    elsif (params[:facility_id] != '') &&  (params[:doctor_id] != '')
      @appointments = Appointment.where(:facility_id.in => my_facilities, appointmentdate: params[:start_date].to_date..params[:end_date].to_date, facility_id: params[:facility_id], consultant_id: params[:doctor_id], :appointmentstatus.nin => [89925002])
    end
    @facility = (Facility.find_by(id: params[:facility_id]).name if params[:facility_id].present?) || 'All'
    @current_time = Time.current.strftime('%d%m%y_%I%M%P')
    @filename = "#{@facility}_healthgraph_appointments_#{@current_time}.xls"
    respond_to do |format|
      format.js
      format.html
      format.xls { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  def register
    @appointment_id = params[:appointment_id]
    @patient = Patient.find_by(id: params[:id])
    if (@patient.try(:reg_status) == false)
      @patient.update(reg_status: true, reg_date: Date.current, reg_time: Time.current, reg_facility_id: current_facility.id.to_s)
      create_patient_identifier(@patient, current_user, current_facility)
      create_patient_search(@patient)
    end
    Mis::ClinicalReportsHelper.prepare_mis_job(@appointment_id.to_s) if @appointment_id.present?
  end

  private

  def details_view_params
    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @current_date = if params[:current_date].present?
                      Date.parse(params[:current_date])
                    else
                      @patient.try(:reg_date) || Date.current
                    end

    @details_section_path = 'patient'
    @patient = Patient.find_by(id: params[:patient_id])

    return if @patient.nil?

    facility_id = current_facility.id
    user_id = current_user.id
    organisation_id = current_user.organisation_id

    if current_facility.country_id == 'VN_254'
      occupation_list = Global.send('occupation_list').send('sets')
      occupation_hash = occupation_list.pluck(:snomedcode, :name).to_h
      @occupation_name = occupation_hash[@patient&.occupation]
    end


    # Adverse Event
    @adverse_events = AdverseEvent.where(patient_id: @patient.id)

    # Referral
    @initial_referral_type = PatientReferralType.where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]

    @past_appointment = AppointmentListView.where(patient_id: @patient.try(:id), :appointment_date.lt => Date.current, :current_state.nin => ['Deleted', 'Scheduled']).order(appointment_date: :desc)
    patient_asset = @patient.patientassets
    @patient_asset = if patient_asset.count > 0
                       if patient_asset.last.asset_path_url.present?
                         patient_asset.all[-1].asset_path_url
                       else
                         'placeholder.png'
                       end
                     else
                       'placeholder.png'
                     end

    @patient_self_histories = PatientSelfHistory.where(patient_id: @patient.id).order_by('created_at DESC')


    @patientid = @patient.id
    @patient_note = PatientNote.where(patient_id: @patientid).order(created_at: :desc).limit(5)
    @counsellor_note = CounsellorNote.where(patient_id: @patient.id).order(created_at: :desc).limit(5)

    # UserState
    @user_state = user_state
    if @current_facility.show_user_state && @user_state.present? && @user_state.active_state != 'OPD'
      @show_user_state = true
      @user_state_color = @user_state.state_color
      @active_state = @user_state.active_state
    end

    # NABH
    @nabh_setting = NabhSetting.find_by(facility_id: current_facility.id.to_s)

    # Admission Params
    @existing_admission = Admission.find_by(patient_id: @patient.id, isdischarged: false, is_deleted: false)
    @admission_list_view = AdmissionListView.find_by(admission_id: @existing_admission.try(:id))
    @ot_schedules = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false)
    @admission_case_sheet = @existing_admission.try(:case_sheet)



    @patient_certificates = UserNote.where(patient_id: @patient.id)

    # TokenSettings
    @token_setting = TokenSetting.find_by(facility_id: facility_id)

    # PatientCard
    @patient_card_enabled = OrganisationsSetting.find_by(organisation_id: @current_facility.organisation_id).try(:patient_card_enabled)
    @calculate_age = @patient.calculate_age

    @org_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
  end
  # def patient_params
  #   params.permit(:firstname, :lastname, :salutation, :gender, :age, :mobilenumber, :appointmenttype, :appointmentdate, :appointmenttime)
  # end

  # def add_patient_history_params
  #   params.require(:patient).permit(:fullname, :gender,:dob, :age, :mobilenumber,:email, :blood_group,:address_1,:address_2,:city,:state,:pincode,:emergencycontactname, :emergencymobilenumber, :maritalstatus, :specialstatus, :occupation, patientassets_attributes: [:asset_path],patient_history_attributes: [ :patient_id, :patientid, :templatetype, :templateid, patientpersonalhistory_attributes: [problems: [] ], patientallergyhistory_attributes: [:others, antimicrobialagents: [], nsaids: [], antifungalagents: [], antiviralagents: [], contact: [],eyedrops: [], food: [] ] ])
  # end

  # def update_patient_params
  #   params.require(:patient).permit(:id,:fullname,:firstname,:lastname, :gender,:dob, :age, :secondarymobilenumber, :mobilenumber,:email, :blood_group,:address_1,:address_2,:city,:state,:pincode,:emergencycontactname, :emergencymobilenumber, :maritalstatus, :specialstatus, :occupation, patientassets_attributes: [:id,:asset_path],patient_history_attributes: [ :id,:patient_id, :patientid, :templatetype, :templateid, patientpersonalhistory_attributes: [problems: [] ], patientallergyhistory_attributes: [:id,:others, antimicrobialagents: [], nsaids: [], antifungalagents: [], antiviralagents: [], contact: [],eyedrops: [], food: [] ] ])
  # end

  # def add_patient_history_params
  #   params.require(:patient).permit!
  # end

  # def update_patient_params
  #   params.require(:patient)
  # end

  # def add_patient_assets_params
  #   params.require(:patient).permit(:id,patientassets_attributes: [:asset_path])
  # end

  def create_patient_summary_asset_upload
    params.require(:patient_summary_asset_upload).permit(:name, :ancestry, :patient_id).merge(is_folder: 'Y', is_custom: 'Y')
  end

  def patient_type
    @patient_type = PatientType.where(is_active: true, organisation_id: current_user.organisation_id).pluck(:label, :id)
  end

  def create_patient_identifier(patient, current_user, current_facility)
    patient_identifier = PatientIdentifier.create!(patient_id: patient.id, organisation_id: current_user.organisation_id, bkp_patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
    patient_org_id = SequenceManagers::GenerateSequenceService.call('patient', patient.id.to_s, {organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id.to_s, region_id: current_facility.try(:region_master_id).to_s})
      patient_identifier.update(patient_org_id: patient_org_id)
  end

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

    PatientSearch.create(search: search.downcase, patient_id: patient.id, patient_name: patient_name,
                         mobile_number: mobile_number, mr_no: patient.patient_mrn,
                         patient_identifier_id: patient_identifier_id, reg_hosp_ids: reg_hosp_ids,
                         patient_identifier_id_search: patient_identifier_id_search,
                         mr_no_search: mr_no_search.downcase, patient_name_search: patient_name_search)
  end
end
