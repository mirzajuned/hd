# rubocop:disable all
class OpdAppointmentsController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  layout 'loggedin'

  def new_appointment_from_summary
    @appointment_date = Date.current.to_s
    if params[:start_time] != '' && params[:end_time] != ''
      @start_time = params[:start_time]
      @end_time = params[:end_time]
    else
      @start_time = Time.current.strftime('%H:%M')
      @end_time = ''
    end

    # @doctor = @appointment.doctor
    # @user = User.find(@doctor)

    @patient_id = params[:patient_id]
    @user = current_user
    @facilities = Common.new.fetch_facilities(user: @user)
    @appointment_types = AppointmentType.where(user_id: current_user.id, is_active: true)

    current_facility_array
    respond_to do |format|
      format.js {}
    end
  end

  def save_appointment_from_summary
    current_facility_array
    opdfollowupdate = Time.strptime(appointment_params[:opdfollowupdate], '%m/%d/%Y')
    opdfollowuptime = appointment_params[:opdfollowuptime]

    new_appointment = Appointment.new(appointmentdate: opdfollowupdate, start_time: opdfollowuptime, patient_id: @patient.id, appointment_type_id: appointment_params[:appointment_type_id], consultant_id: current_user.id, user_id: current_user.id, facility_id: appointment_params[:appointment_facility], department_id: '485396012', departmenttype: 440655000, appointmentstatus: 416774000, display_id: CommonHelper.get_opd_record_identifier(@user))
    new_appointment.save

    # get_daily_reports
    # Reports::Opd::Appointments.new(new_appointment).call
  end

  def newappointment
    @appointment_date = if params[:appointmentdate] != ''
                          params[:appointmentdate]
                        else
                          Date.current.to_s
                        end

    # if params[:current_doctor]
    #   @current_doctor = Doctor.find(params[:current_doctor]).only(:fullname, :id)
    #   p @current_doctor
    # end

    if params[:start_time] != '' && params[:end_time] != ''
      @start_time = params[:start_time]
      @end_time = params[:end_time]
    else
      @start_time = Time.current.strftime('%H:%M')
      @end_time = ''
    end
    current_facility_array

    respond_to do |format|
      format.js {}
    end
  end

  def freshappointmentype
    current_facility_array
    @appointment_date = params['appointment_date']
    @start_time = params['start_time']
    @end_time = params['end_time']
    @patient = Patient.new
    1.times { @patient.appointments.build }
    @patient.build_patient_history.initialize_nested_objects
    1.times { @patient.patientassets.build }
    @patient.appointments[0].departmenttype = 440655000
    @patient.appointments[0].appointmentstatus = 416774000
    @patient.appointments[0].appointmentdate = @appointment_date
    @patient.appointments[0].start_time = @start_time
    @patient.appointments[0].end_time = @end_time
    @patient.appointments[0].department_id = '485396012'
    @patient.appointments[0].user_id = current_user.id

    @facilities = Common.new.fetch_facilities(user: current_user)

    @departments = Common.new.fetch_departments(facilities: @facilities)

    @user = User.where(:role_ids.in => [158965000], :facility_ids.in => [current_facility.id])[0]
    @date = Date.parse(@appointment_date).midnight
    if params[:current_doctor]
      @current_doctor = if params[:current_doctor] == 'all'
                          ''
                        else
                          User.where(id: params[:current_doctor]).pluck(:fullname, :id).first
                        end
      # p @current_doctor
    end

    # inacase of doctor_signin only doctor's name and doctor's appointment type should be seen.
    if current_user.role_ids.include? 158965000
      @users = []
      @users << current_user
      @appointment_types = AppointmentType.where(user_id: current_user.id, is_active: true)
    else

      @users = Common.new.fetch_users(org_type: current_user.organisation.type, organisation_id: current_user.organisation.id, facility_id: current_facility.id, department_id: @departments.first.id)
      @appointment_types = AppointmentType.where(user_id: @users[0].try(:id), is_active: true)

    end

    @facility_id = current_facility.id

    respond_to do |format|
      format.js {}
    end
  end

  def addfreshappointment
    current_facility_array
    if params[:patient]['appointments_attributes']['0']['end_time'] == ''
      params[:patient]['appointments_attributes']['0']['end_time'] = Time.zone.parse(params[:patient]['appointments_attributes']['0']['start_time']) + AppointmentType.find(params[:patient]['appointments_attributes']['0']['appointment_type_id']).duration.minutes
    end
    # params[:patient][:appointments_attributes]['0'][:user_id] = params['user-filter']
    # params[:patient][:appointments_attributes]['0'][:department_id] = User.find(params['user-filter']).department_id
    params[:patient][:appointments_attributes]['0'][:facility_id] = params['appointment-facility-filter']
    params[:patient][:appointments_attributes]['0'][:doctor] = params['doctors-filter']
    params[:patient][:appointments_attributes]['0'][:display_id] = CommonHelper.get_opd_record_identifier(current_user)
    params[:patient][:reg_hosp_ids] = [current_user.organisation_id.to_s]
    params[:patient][:reg_date] = Date.current
    params[:patient][:reg_time] = Time.current
    params[:patient][:fullname] = (params[:patient][:salutation] + ' ' + params[:patient][:firstname] + ' ' + params[:patient][:lastname]).to_s.strip

    # @patient = Patient.new(appointment_patient_create_params)

    @patient = Patientdata::Create.new(appointment_patient_create_params, current_user).createpatient

    # if @patient
    #   unless params[:patient][:patientassets_attributes]
    #     media =  File.open(Rails.root+"app/assets/images/placeholder.png")
    #     Patientasset.create(patient_id: @patient.id,asset_path: media)
    #   end
    #     PatientIdentifier.create(:patient_id => @patient.id,:organisation_id => current_user.organisation_id,:patient_org_id => CommonHelper::get_patient_org_identifier(current_user))
    #   if @patient.dob.present?
    #     patient_birthday = PatientBirthday.find_by(patient_id: @patient.id)
    #     if patient_birthday
    #       patient_birthday.update(dob: @patient.dob.strftime("%d%m"))
    #     else
    #       PatientBirthday.create(patient_id: @patient.id,dob: @patient.dob.strftime("%d%m"))
    #     end
    #   end
    #   # model method for exact_age
    #   @patient.get_exact_age(@patient.age.to_i, @patient.age_month.to_i)
    # end

    if (params[:patient][:appointments_attributes]['0'][:ref_doc_name] != '') && !ReferringDoctor.where(name: params[:patient][:appointments_attributes]['0'][:ref_doc_name], hospital_name: params[:patient][:appointments_attributes]['0'][:ref_doc_place], user_id: current_user.id).exists?
      @referring_doc = ReferringDoctor.new
      @referring_doc[:name] = params[:patient][:appointments_attributes]['0'][:ref_doc_name]
      @referring_doc[:hospital_name] = params[:patient][:appointments_attributes]['0'][:ref_doc_place]
      @referring_doc[:speciality] = params[:patient][:appointments_attributes]['0'][:ref_doc_speciality]
      @referring_doc[:mobile_number] = params[:patient][:appointments_attributes]['0'][:ref_doc_number]
      @referring_doc[:email] = params[:patient][:appointments_attributes]['0'][:ref_doc_email]
      @referring_doc[:city] = params[:patient][:appointments_attributes]['0'][:ref_doc_city]
      @referring_doc[:user_id] = current_user.id
      @referring_doc.save
      @patient.update_attributes(referring_doctor_id: @referring_doc.id)
    else
      puts @patient
      @patient.update_attributes(referring_doctor_id: params[:patient][:appointments_attributes]['0'][:ref_doc_id])
    end
    @source_type = params[:patient][:appointments_attributes]['0'][:source]
    if (params[:patient][:appointments_attributes]['0'][:source_detail_family] != '') && (params[:patient][:appointments_attributes]['0'][:source] == 'family')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient][:appointments_attributes]['0'][:source_detail_family]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!

    elsif (params[:patient][:appointments_attributes]['0'][:source_detail] != '') && (params[:patient][:appointments_attributes]['0'][:source] == 'referingdoc')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient][:appointments_attributes]['0'][:source_detail]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!

    elsif (params[:patient][:appointments_attributes]['0'][:source_detail_internet] != '') && (params[:patient][:appointments_attributes]['0'][:source] == 'internet')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient][:appointments_attributes]['0'][:source_detail_internet]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!

    elsif (params[:patient][:appointments_attributes]['0'][:newspaper_source_info] != '') && (params[:patient][:appointments_attributes]['0'][:source] == 'newspaper')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient][:appointments_attributes]['0'][:newspaper_source_info]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!

    elsif (params[:patient][:appointments_attributes]['0'][:source_detail] != '') && (params[:patient][:appointments_attributes]['0'][:source] == 'camp')
      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient][:appointments_attributes]['0'][:source_detail]
      @patient_source[:source_date] = params[:patient][:appointments_attributes]['0'][:source_date]
      @patient_source[:source_doctor] = params[:patient][:appointments_attributes]['0'][:source_doctor]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!
    elsif (params[:patient][:appointments_attributes]['0'][:source_info] != '') && (params[:patient][:appointments_attributes]['0'][:source] == 'other')
      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient][:appointments_attributes]['0'][:source_info]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!
    end
    @appointment = @patient.appointments.order('created_at DESC')[0]
    # @appointment.update_attributes(patient_name: @patient.fullname)
    # PatientAppointmentConfirmationSmsJob.perform_later(@appointment.id.to_s)
    # ConfirmationEmailJob.perform_later(@appointment.id.to_s) #uncomment when user setting implemented
    # get_daily_reports
    # Reports::Opd::Appointments.new(@appointment).call
    # code for PatientOtherIdentifier
    @mr_no = params[:mr_no]
    @ip_no = params[:ip_no]

    unless @mr_no == '' && @ip_no == ''
      patient_other_identifier = PatientOtherIdentifier.new
      patient_other_identifier.mr_no = @mr_no
      patient_other_identifier.ip_no = @ip_no
      patient_other_identifier.patient_id = @patient.id
      patient_other_identifier.organisation_id = current_user.organisation.id
      patient_other_identifier.facility_id = @appointment.facility_id.to_s
      patient_other_identifier.doctor = params['doctors-filter']
      patient_other_identifier.save
    end
    refer_relation = ReferdocPatientRelation.new
    refer_relation.refer_doc_id = if !@referring_doc.nil?
                                    @referring_doc.id
                                  else
                                    params[:patient][:appointments_attributes]['0'][:ref_doc_id]
                                  end
    refer_relation.patient_id = @patient.id
    refer_relation.save!
    # create clinical workflow tables
    # start_cinical_workflow
    unless @patient.referring_doctor_id.nil?
      # ReferingdocsmsJob.perform_later(@appointment.id.to_s,@patient.referring_doctor_id.to_s)
    end

    # Change date in startTime According to appointmentDate
    @hours = if params[:meridian] == 'AM'
               if params[:hour] == '12'
                 0o0
               else
                 params[:hour].to_i
               end
             else
               if params[:hour] == '12'
                 params[:hour].to_i
               else
                 params[:hour].to_i + 12
                        end
             end
    @minutes = params[:minute].to_i
    @date = params[:patient][:appointments_attributes]['0'][:appointmentdate].split('/')[0]
    @month = params[:patient][:appointments_attributes]['0'][:appointmentdate].split('/')[1]
    @year = params[:patient][:appointments_attributes]['0'][:appointmentdate].split('/')[2]
    @appointmenttime = Time.new(@year, @month, @date, @hours, @minutes, 0)
    @appointment.update(start_time: @appointmenttime, end_time: @appointmenttime + AppointmentType.find(params[:patient]['appointments_attributes']['0']['appointment_type_id']).duration.minutes)

    respond_to do |format|
      format.js {}
    end

    Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'SCHEDULED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
    # PatientGcmJob.set(wait: 1.minutes).perform_later(@patient.id.to_s, "Patient", "Create", current_user.organisation_id.to_s)
    # AppointmentGcmJob.set(wait: 2.minutes).perform_later(@appointment_id.to_s, "Appointment", "Create", current_user.organisation_id.to_s)
  end

  def addfollowupappointment
    @appointment_id = params[:appointment_id]
    @datepicker_date = Date.strptime(params[:followupappointmentdate], '%d/%m/%Y').strftime('%Y-%m-%d').to_s
    if params[:end_time] == ''
      end_time = Time.zone.parse(params['followupappointmenttime']) + AppointmentType.find(params['appointment_type_id']).duration.to_i.minutes
    else
      end_time = params[:end_time]
    end
    # patient_name=Patient.find_by(id: params[:patient_id]).fullname
    @appointment = Appointment.new(appointmentdate: params[:followupappointmentdate], start_time: params[:followupappointmenttime], end_time: end_time, appointment_type_id: params[:appointment_type_id], patient_id: params[:patient_id], consultant_id: params['doctors-filter'], user_id: current_user.id, facility_id: params['appointment-facility-filter'], department_id: params['department-filter'], departmenttype: params[:departmenttype], appointmentstatus: 416774000, display_id: CommonHelper.get_opd_record_identifier(current_user))

    if params[:opd_referral_id].present?
      @opdreferral = OpdReferral.find(params[:opd_referral_id])
      @opdreferral.update(converted_to_appointment: true, converted_appointment_id: @appointment.id)
      @appointment.opd_referral_id = params[:opd_referral_id]
      @appointment.referral = true
      @appointment.referral_created_on = @opdreferral.created_on
      @appointment.referring_doctor = @opdreferral.from_doctor_name
      @appointment.referee_doctor = @opdreferral.to_doctor_name
      @appointment.to_facility_name = @opdreferral.to_facility_name
      @appointment.from_facility_name = @opdreferral.from_facility_name
      @appointment.referral_note = @opdreferral.referring_note
    end
    @appointment.save!
    #:department_id => User.find(params['user-filter']).department_id
    # PatientAppointmentConfirmationSmsJob.perform_later(@appointment_id.to_s)

    # Change date in startTime According to appointmentDate
    @hours = if params[:meridian] == 'AM'
               if params[:hour] == '12'
                 0o0
               else
                 params[:hour].to_i
               end
             else
               if params[:hour] == '12'
                 params[:hour].to_i
               else
                 params[:hour].to_i + 12
                        end
             end
    @minutes = params[:minute].to_i
    @date = params[:followupappointmentdate].split('/')[0]
    @month = params[:followupappointmentdate].split('/')[1]
    @year = params[:followupappointmentdate].split('/')[2]
    @appointmenttime = Time.new(@year, @month, @date, @hours, @minutes, 0)
    @appointment.update(start_time: @appointmenttime, end_time: @appointmenttime + AppointmentType.find(params[:appointment_type_id]).duration.minutes)

    # ConfirmationEmailJob.perform_later(@appointment.id.to_s)
    # get_daily_reports
    # Reports::Opd::Appointments.new(@appointment).call
    # code for PatientOtherIdentifier
    @mr_no = params[:mr_no]
    @ip_no = params[:ip_no]

    unless @mr_no == '' && @ip_no == ''
      patient_other_identifier = PatientOtherIdentifier.new
      patient_other_identifier.mr_no = @mr_no
      patient_other_identifier.ip_no = @ip_no
      patient_other_identifier.patient_id = params[:patient_id]
      patient_other_identifier.organisation_id = current_user.organisation.id
      patient_other_identifier.facility_id = @appointment.facility_id.to_s
      patient_other_identifier.doctor = params['doctors-filter']
      patient_other_identifier.save
    end
    if current_user.role_ids.include? 499992366 # counsellor
      counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: @appointment_id)
      counsellor_workflow.converted
      converted_state_array = counsellor_workflow.converted_state
      converted_state_array << 'Investigation'
      counsellor_workflow.update(converted_state: converted_state_array)
    end
    ######
    # start_cinical_workflow
    respond_to do |format|
      format.js {}
    end

    Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'SCHEDULED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
    # PatientGcmJob.set(wait: 1.minutes).perform_later(params[:patient_id].to_s, "Patient", "Create", current_user.organisation_id.to_s)
    # AppointmentGcmJob.set(wait: 2.minutes).perform_later(@appointment_id.to_s, "Appointment", "Create", current_user.organisation_id.to_s)
  end

  def save_patients_appointment_fees
    params[:appointment_id]
    @appointment = Appointment.find(params[:appointment_id])
    @appointment.update(patients_appointment_fees: params[:pat_fee])
    respond_to do |format|
      format.js {}
    end
  end

  def add_followup_appointment_opd_record
    @appointment = Appointment.create!(appointmentdate: params[:followupappointmentdate], appointmenttime: params[:followupappointmenttime], visittype: 'Followup', patient_id: params[:patient_id], user_id: current_user.id, facility_id: current_facility.id, department_id: '485396012', departmenttype: params[:departmenttype], appointmentstatus: 416774000)
    respond_to do |format|
      format.js {}
    end
  end

  def showcalendar
    # @current_date = Date.current
    # current_facility_array
    # @datepicker_date = "#{Date.current.strftime('%Y-%m-%d')}"
    # @facilities = Common.new.fetch_facilities(:user => current_user)

    # if current_user.roles[0].try(:name) == "doctor" || current_user.roles[1].try(:name) == "doctor"
    #   @departments = Array.new
    #   @departments << Department.find_by(id: current_user.department_id)
    #   @users_array = [[current_user.fullname, current_user.id]]
    # else
    #   @departments = Common.new.fetch_departments(:facilities => @facilities)
    #   @users = Common.new.fetch_users(:org_type => current_user.organisation.type,:organisation_id => current_user.organisation.id,:facility_id => current_facility.id,:department_id => @departments.first.id)
    #   @users_array = @users.map { |user| [user.fullname, user.id] }
    #   @users_array = [["All Users", "0"]] + @users_array
    # end

    # user_default_slot = AppointmentType.find_by(:user_id => @users_array[0][1], :is_default => true, :is_active => false)
    # if user_default_slot
    #   @user_default_slot_time = user_default_slot.duration
    # else
    #   @user_default_slot_time = 15
    # end
    # @timeline = schedule_timeline(current_facility, @users_array[0][1])
    # @current_facility_doctors = User.where(:facility_ids.in => [current_facility.id],:role_ids.in => [158965000],is_active: true,department_id: current_user.department_id)
    # respond_to do |format|
    #   format.js {}
    #   format.html {}
    # end
    redirect_to outpatients_appointment_scheduler_path
  end

  def filteropdappointmentlist
    @appointmentdate = Date.parse(params[:appointmentdate])
    @current_facility_doctors = User.where(:facility_ids.in => [current_facility.id], :role_ids.in => current_facility['consultant_role_ids'], is_active: true).sort_by{|i| i.fullname.downcase}.pluck(:fullname, :id)
    respond_to do |format|
      format.js { render partial: 'opd_appointments/filteropdappointmentlist.js.erb', layout: false }
    end
  end

  # Prints Appointment For all Facility belonging to the user
  def printopdappointmentlist
    @organisation = current_user.organisation
    @facility = params[:facility_id] || current_facility.id
    @datepicker_date = Date.parse(params[:appointmentdate])

    @specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @available_specialties = Specialty.where(:id.in => @specialty_ids).map { |s| { id: s.id.to_s, name: s.name } }

    if current_user.has_role?(:doctor)
      @appointment_list = Appointment.where(appointmentdate: @datepicker_date, appointmentstatus: '416774000', facility_id: @facility, consultant_id: current_user.id.to_s, :specialty_id.in => @specialty_ids).order('start_time ASC')
    else
      if params[:doctor].present?
        @appointment_list = Appointment.where(appointmentdate: @datepicker_date, appointmentstatus: '416774000', facility_id: @facility, consultant_id: params[:doctor].to_s, :specialty_id.in => @specialty_ids).order('start_time ASC')
      else
        @appointment_list = Appointment.where(appointmentdate: @datepicker_date, appointmentstatus: '416774000', facility_id: @facility, :specialty_id.in => @specialty_ids).order('start_time ASC')
      end
    end

    @ots = OtSchedule.where(:patient_id.in => @appointment_list.pluck(:patient_id), :otdate.gte => Date.current, is_deleted: false, operation_done: false)

    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'opd_appointments/printopdappointmentlist', pdf: 'AppointmentList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f, bottom: @print_settings[0]['footer_height'].to_f }, orientation: 'Landscape' }
    end
  end

  # Prints Appointment Facility Wise
  def printappointment_dashboard
    @organisation = current_user.organisation
    @facility = Facility.find_by(id: params[:facility_id])
    @user = User.find_by(id: params[:doctor])
    if [[158965000], [158965000, 6868009]].include? current_user.role_ids
      @appointmentlist = Appointment.where(appointmentdate: Date.current, facility_id: @facility.id, consultant_id: current_user.id)
    else
      @appointmentlist = if @user.nil?
                           Appointment.where(appointmentdate: Date.current, facility_id: @facility.id)
                         else
                           Appointment.where(appointmentdate: Date.current, facility_id: @facility.id, consultant_id: @user.id)
                         end
    end
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'opd_appointments/printappointment_dashboard.pdf.erb', pdf: 'AppointmentList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def showotcalendar
    @datepicker_date = Date.current.strftime('%Y-%m-%d').to_s
    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  def showday
    # # For Patient Summary
    # if params[:appointment]
    #   @patient = Patient.find_by(id: params[:appointment][:patientid])
    #   @appointment = Appointment.find_by(id: params[:appointment][:appointmentid])
    # end
    # @current_date = Date.parse("#{params[:appointmentday]}", "%d-%b-%Y")
    # @datepicker_date = "#{Date.parse("#{params[:appointmentday]}", "%d-%b-%Y").strftime("%Y-%m-%d")}"
    # @appointment_day_ddmonthyear = params[:appointmentday] ?  "#{Date.parse("#{params[:appointmentday]}", "%d-%b-%Y").strftime("%d-%b-%Y")}" : "#{Date.current.strftime("%d-%b-%Y")} (Today)"
    # if params.has_key?("appointment")
    #     @appointment = Appointment.find(params[:appointment][:appointmentid])
    #     @appointment.update_attributes({:arrived => true, :engaged => false})
    # end
    # current_facility_array
    # if current_user.roles[0].try(:name) == "doctor" || current_user.roles[1].try(:name) == "doctor"
    #   @departments =Array.new
    #   @departments << Department.find_by(id: current_user.department_id)
    #   @users_array = [[current_user.fullname, current_user.id]]

    # else
    #   # @departments = Common.new.fetch_departments(:facilities => @facilities)                         for now in case of nurse only her department is needed
    #   @departments =Array.new
    #   @departments << Department.find_by(id: current_user.department_id)
    #   @users = Common.new.fetch_users(:org_type => current_user.organisation.type,:organisation_id => current_user.organisation.id,:facility_id => current_facility.id,:department_id => @departments.first.id)
    #   @users_array = @users.map { |user| [user.fullname, user.id] }
    #   @users_array = [["All Users", "0"]] + @users_array
    # end
    # @current_facility_doctors = User.where(:facility_ids.in => [current_facility.id],:role_ids.in => [158965000],is_active: true,department_id: current_user.department_id)
    # # if params["from"] == "complete_btn"
    # #   @from_source = "summary"
    # #   @summary_appointment = params[:appointment][:appointmentid]
    # # end
    # if current_user.has_role?'counsellor'
    #   setup_data_for_counsellor
    # end
    # @refresh_appointment_id = params[:appointment_id]
    # @refresh_appointment_tab = params[:tab]
    # respond_to do |format|
    #   format.js {}
    #   format.html {}
    # end
    redirect_to outpatients_appointment_management_path
  end

  def showday_data
    # facility = Facility.find(params[:facility_id])
    facility = current_facility
    if params[:department_id].to_i == 0
      department_ids = facility.department_ids
      options = { :appointmentdate => params[:current_date], :facility_id => facility.id, :department_id.in => department_ids, :appointmentstatus.in => [416774000, 58334001] }
    else
      options = { :appointmentdate => params[:current_date], :facility_id => facility.id, :department_id => params[:department_id], :appointmentstatus.in => [416774000, 58334001] }
    end

    if params[:status] == 'waiting'
      options = options.merge({ seen: false, arrived: true })
    elsif params[:status] == 'engaged'
      options = options.merge({ engaged: true })
    elsif params[:status] == 'completed'
      options = options.merge({ seen: true })
    end

    # if params[:doctor].present? && params[:doctor].to_i !=0
    options = options.merge({ consultant_id: params[:doctor] }) if params[:doctor].present? && params[:doctor] != 'all'

    if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
      options = options.merge({ consultant_id: current_user.id })
    end
    if params[:q]
      # options = options.merge({patient_name: /#{params[:q]}/i})
      options = options.merge({ :patient_id.in => Patient.where(fullname: /#{Regexp.escape(params[:q])}/i).pluck(:id) })
    end
    @appointment_list = Appointment.where(options).order('start_time asc')
    # .order("start_time "+params[:sSortDir_0])
    # NEED TO SEND ASC DESC
    @total_appointment_count = Appointment.where(options).count

    if params[:sSearch] != ''
      patients_list = @appointment_list.map(&:patient_id)
      letter = params[:sSearch]
      capital_letter = letter.try(:capitalize)
      all_capital_letter = letter.try(:upcase)
      patients_final_list = Patient.where(:id.in => patients_list, :fullname => /^#{letter}|#{capital_letter}|#{all_capital_letter}/).map(&:_id)
      options = options.merge({ :patient_id.in => patients_final_list })
      @appointment_list = Appointment.where(options).order('start_time asc')
      # .order("start_time "+params[:sSortDir_0])
    end
    @appointment_list_count = Appointment.where(options).count

    # @sEcho = params[:sEcho]

    @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, version: 'v21.0')
    @cash_register_templates = CashRegisterTemplate.where(user_id: current_user.id)
    respond_to do |format|
      format.json {}
    end
  end

  def showday_appointment_details
    # fail
    # Kumar Abinash
    # => Renders details pane content with appointmet details in calendar view
    @newcounsellornote = CounsellorNote.new
    @showcounsellornote = CounsellorNote.where(organisation_id: current_user.organisation_id, user_id: current_user.id).order(created_at: :desc)
    @newpatientnote = PatientNote.new
    @showpatientnote = PatientNote.where(organisation_id: current_user.organisation_id).order(created_at: :desc)

    @appointment = Appointment.includes(:patient, :appointment_type).find(params[:appointment_id])
    # @opd_record =

    if current_facility.show_finances
      @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, version: 'v21.0')
      @cash_register_templates = CashRegisterTemplate.where(user_id: current_user.id)
    end
    # if current_user.has_role?("doctor")
    #   @doc_reminder_note = DocReminderNote.find_by(patient_id: @appointment.patient.id.to_s)
    #   if @doc_reminder_note == nil
    #     @reminder_text = ""
    #   else
    #     @reminder_text = @doc_reminder_note.reminder_text
    #   end
    # end

    if current_facility.clinical_workflow
      @pat_workflow = OpdClinicalWorkflow.includes(:opd_clinical_workflow_state_transitions).find_by(appointment_id: params[:appointment_id])
      states = @pat_workflow.opd_clinical_workflow_state_transitions.pluck(:to)
      @with_user = User.find_by(id: @pat_workflow.user_id)
      @states = states.map(&:capitalize)
      # @user_stats = FacilityUserStat.where(facility_id: current_facility.id)
      @advance = AdvancePayment.where(patient_id: @appointment.patient_id, type: 'OPD', advance_state: 'None')
      @counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: @appointment.id.to_s)
    end

    @patient = @appointment.patient
    @eyedrop_allergy = []
    if @patient.patient_history.patientallergyhistory.eyedrops.present?
      @patient.patient_history.patientallergyhistory.eyedrops.each do |eyedrops|
        @eyedrop_allergy.push(@patient.get_label_for_allergy('eyedrops', eyedrops))
      end
    end
    @current_facility_doctors = User.where(:facility_ids.in => [current_facility.id], :role_ids.in => [158965000], is_active: true)

    @all_current_facility_users = User.where(:facility_ids.in => [current_facility.id], is_active: true) - [current_user]
    @current_facility_optometrist = User.where(:facility_ids.in => [current_facility.id], :role_ids.in => [28229004], is_active: true)
    @current_facility_lab_technician = User.where(:facility_ids.in => [current_facility.id], :role_ids.in => [159282002], is_active: true)
    @current_facility_receptionists = User.where(:facility_ids.in => [current_facility.id], :role_ids.in => [159561009], is_active: true)
    @current_facility_counsellor = User.where(:facility_ids.in => [current_facility.id], :role_ids.in => [499992366], is_active: true)
    @current_date = params[:current_date]
    @last_opdrecord = OpdRecord.where(patientid: @appointment.patient.id.to_s, appointmentid: @appointment.id.to_s).order('created_at DESC')[0]

    # comment patient tracker cannot find usage
    # @patient_tracker = PatientTracker.find_by(patient_id: @appointment.patient_id, tracker_removed: false)

    respond_to do |format|
      format.html { render partial: 'opd_appointments/list/showday_appointment_details.html', layout: false }
    end
  end

  def save_patient_note
    @showpatientnote = PatientNote.where(organisation_id: current_user.organisation_id).order(created_at: :desc)
    @newnote = PatientNote.new(patient_note_params)
    @newnote.organisation_id = current_user.organisation_id.to_s
    @newnote.user_id = current_user.id.to_s
    @newnote.created_by = current_user.fullname
    @patient_note = PatientNote.where(patient_id: params[:patient_id]).order(created_at: :desc).limit(5)
    if @newnote.save
      @patientid = @newnote.patient_id
      respond_to do |format|
        format.js { render 'opd_appointments/refresh_patient_note_list.js.erb', layout: false }
      end
    end
  end

  def show_more_notes_appointment
    @patient = Patient.find_by(id: params[:patient_id])
    @patientid = @patient.id
    @patient_note = PatientNote.where(patient_id: params[:patient_id]).order(created_at: :desc).skip(params[:count].to_i).limit(5)
    respond_to do |format|
      format.js { render 'opd_appointments/show_hide_patient.js.erb', layout: false }
    end
  end

  def show_more_notes_counsellor
    @patient = Patient.find_by(id: params[:patient_id])
    @patientid = @patient.id
    @counsellor_note = CounsellorNote.where(patient_id: params[:patient_id]).order(created_at: :desc).skip(params[:count].to_i).limit(5)
    respond_to do |format|
      format.js { render 'opd_appointments/show_more_notes_counsellor.js.erb', layout: false }
    end
  end

  def save_counsellor_note
    @current_user = current_user
    @showcounsellornote = CounsellorNote.where(organisation_id: @current_user.organisation_id, user_id: @current_user.id).order(created_at: :desc)
    @newnote = CounsellorNote.new(patient_note_params)
    @newnote.organisation_id = @current_user.organisation_id.to_s
    @newnote.user_id = @current_user.id.to_s
    @patient = Patient.find_by(id: params[:patient_id])
    @patientid = @patient.id
    if @newnote.save
      @counsellor_note = CounsellorNote.where(patient_id: params[:patient_id]).order(created_at: :desc).limit(5)
      @patientid = @newnote.patient_id
      respond_to do |format|
        format.js { render 'opd_appointments/refresh_counsellor_note_list.js.erb', layout: false }
      end
    end
  end

  # def save_note_is_complete
  #   @showpatientnote = TaskList.all.where(organisation_id: current_user.organisation_id).order(:created_at => :desc)
  #   @task = TaskList.find(params[:task_id])
  #   if @task.update(is_complete: params[:is_complete])
  #     respond_to do |format|
  #       format.js { render 'main/dashboard_content/task_list/refresh_task_list.js.erb', layout: false}
  #     end
  #   end
  # end

  def delete_note
    @patient = Patient.find_by(id: params[:patient_id])
    @patientid = @patient.id
    @showpatientnote = PatientNote.where(organisation_id: current_user.organisation_id).order(created_at: :desc)
    @note = PatientNote.find_by(id: params[:note_id])
    if @note.try(:delete)
      @patient_note = PatientNote.where(patient_id: @note.patient_id).order(created_at: :desc)
      respond_to do |format|
        format.js { render 'opd_appointments/refresh_patient_note_list.js.erb', layout: false }
      end
    else
      head :ok
    end
  end

  def delete_counsellor_note
    @showcounsellornote = CounsellorNote.where(organisation_id: current_user.organisation_id).order(created_at: :desc)
    @note = CounsellorNote.find(params[:note_id])

    @note.delete if @note.present?
    @patient = Patient.find_by(id: params[:patient_id])
    @patientid = @patient.id
    @counsellor_note = CounsellorNote.where(patient_id: params[:patient_id]).order(created_at: :desc)

    respond_to do |format|
      format.js { render 'opd_appointments/delete_counsellor_note_list.js.erb', layout: false }
    end
  end

  def new_features_seen
    # current_user.opd_feature_notified = true;
    if params[:counter]
      if current_user.respond_to?(:opd_feature_notify_counter)
        current_user.update(opd_feature_notify_counter: current_user.opd_feature_notify_counter + 1)
      else
        current_user.update(opd_feature_notified: false)
        current_user.update(opd_feature_notify_counter: 1)
      end
    else
      current_user.update(opd_feature_notified: true)
      current_user.update(opd_feature_notify_counter: 5)
    end

    respond_to do |f|
      f.json { render json: { "success": true } }
    end
  end

  def get_invoice_amount
    @appointment = Appointment.find(params[:appointment_id])

    respond_to do |format|
      format.json { render json: { amount: @appointment.patients_appointment_fees } }
    end
  end

  def rescheduleappointment
    @appointment = Appointment.find_by(id: params[:appointment_id])
    respond_to do |format|
      format.js {}
    end
  end

  def updateappointment
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @appointment_time = params[:start_time]
    @updated_time = Time.zone.parse(@appointment_time)
    if @appointment.appointment_type_id.to_s != ''
      @reschedule_date = (@appointment.appointmentdate != params[:appointmentdate].to_date || @updated_time != @appointment.start_time)
      if @appointment.update(appointmentdate: params[:appointmentdate], start_time: @updated_time, end_time: @updated_time + @appointment.appointment_type.duration.to_i.minutes, scheduling_time: @updated_time, scheduling_date: @updated_time)
        # case when appointment_type changes
        CommunicationNotificationJob.perform_now('reschedule_appointment', @appointment.id.to_s, @appointment.class.to_s) if @reschedule_date &&  @appointment.appointmenttype == "walkin"
        if @appointment.appointmentdate != @appointment.appointmentdate
          set_update_analytics_params

          Analytics::Appointment::UpdateService.update_appointment_type_count(@appointment.id, @appointment.appointment_type_id, @appointment.facility_id, @appointment.specialty_id, @appointment.appointmentdate)
          Analytics::Appointment::UpdateService.update_appointment_category_type_count(@appointment.id, @appointment.appointment_category_id, @appointment.facility_id, @appointment.specialty_id, @appointment.appointmentdate)
          Analytics::Appointment::UpdateService.update_walkin_appointment_type_count(@appointment.id, @appointment.facility_id, @appointment.specialty_id, @appointment.appointmentdate, @appointment.appointmenttype)
          Analytics::Appointment::UpdateService.update_appointment_created_count(@appointment.id, @appointment.facility_id, @appointment.appointmentdate, @appointment.specialty_id)
          Analytics::UpdateService.call(@analytics_params.to_json, nil, @appointment.facility_id.to_s, 'patient_referral_type')
        end
      end
    end

    # workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
    # if workflow
    #   workflow.update(:appointmentdate => params[:appointmentdate], :start_time => @appointmenttime,:end_time => @appointmenttime + @appointment.appointment_type.duration.to_i.minutes)
    # end

    # PatientAppointmentRescheduleSmsJob.perform_later(@appointment.id.to_s)
    respond_to do |format|
      format.js {}
    end
    Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'RESCHEDULED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
  end

  def quickeyetemplate
    @appointment = Appointment.find(params[:appointment_id])
    @organisation = current_user.organisation
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'OPD')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'opd_appointments/quickeyetemplate', pdf: 'AppointmentList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def cancelappointmentform
    @appointment = Appointment.find(params[:appointment_id])
    respond_to do |format|
      format.js {}
    end
  end

  def cancelappointment
    @appointment = Appointment.find_by(id: params[:appointment_id])
    reset_token
    if @appointment.arrived == true # if patient was already arrived then upon cancelling it should deduct opd_visit_count.
      @patient = Patient.find_by(id: @appointment.patient_id)
      @patient.inc(opd_visit_count: -1)

      Analytics::Appointment::UpdateService.patient_not_arrived(@appointment.id.to_s, current_user.id.to_s, @appointment.facility_id.to_s)

      @appointment.update_attributes({ appointmentstatus: 89925002, token_number: nil, visit_no: nil, arrived: false })
      @workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
      remove_redis_workflow_qm(@workflow)
      QueueManagementJobs::WorkflowJob.perform_later(@workflow.id.to_s, @workflow.facility_id.to_s) if @workflow.present?
    else
      @appointment.update_attributes({ appointmentstatus: 89925002, token_number: nil })
    end
    if @appointment.appointmentstatus == 89925002
      Analytics::Appointment::UpdateService.decrement_appointment_type_count(@appointment.id.to_s)
      Analytics::Appointment::UpdateService.decrement_appointment_category_type_count(@appointment.id.to_s)
      Analytics::Appointment::UpdateService.decrement_walkin_type_count(@appointment.id.to_s)
      Analytics::Appointment::UpdateService.call(@appointment.id.to_s, current_user.id, @appointment.facility_id.to_s)
      Analytics::Patient::UpdateService.decrement_referral_type_count(@appointment.id.to_s)
    end

    # appointment_count = Appointment.where(:appointmentdate => @appointment.appointmentdate,user_id: @appointment.user_id,facility_id: @appointment.facility_id.to_s).count
    # cancelled_appointment_count = Appointment.where(:appointmentstatus => 89925002,:appointmentdate => @appointment.appointmentdate,user_id: @appointment.user_id,facility_id: @appointment.facility_id.to_s).count
    # @daily_report = DailyReport.find_by(date: Date.current,facility_id: @appointment.facility_id.to_s)
    # if @daily_report
    #   @daily_report.update_attributes(appointment_count: (appointment_count-cancelled_appointment_count))
    # end
    # workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
    # if workflow
    #   workflow.cancel
    CommunicationNotificationJob.perform_now('cancel_appointment', @appointment.id.to_s, @appointment.class.to_s)
    # end
    respond_to do |format|
      @datepicker_date = Date.strptime(@appointment.appointmentdate.to_s, '%Y-%m-%d').strftime('%Y-%m-%d')
      @appointmentlist = Appointment.where(appointmentdate: Date.strptime(@appointment.appointmentdate.to_s, '%Y-%m-%d').strftime('%Y-%m-%d'), appointmentstatus: [416774000, 58334001]).order(appointmenttime: :desc)
      # PatientAppointmentCancellationSmsJob.perform_later(@appointment.id.to_s)
      format.js {}
    end
    Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'CANCELLED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
  end

  def reschedulemultiple
    @appointmentlist = Appointment.where(:id.in => (params[:appointment][:appointmentidsarray]).to_s.split(',').collect(&:to_s), :appointmentstatus.in => [416774000, 58334001])
    respond_to do |format|
      format.js {}
    end
  end

  def updatemultiple
    @appointmentlist = Appointment.where(:id.in => params[:appointmentid].to_a.collect(&:to_s))
    if @appointmentlist.all?
      @appointmentlist.each_with_index do |appointment, index|
        end_time = Time.zone.parse(params[:appointmenttime][index]) + appointment.appointment_type.duration.minutes
        appointment.update_attributes({ appointmentdate: params[:appointmentdate][index], start_time: params[:appointmenttime][index], end_time: end_time })
      end
      respond_to do |format|
        format.js {}
      end
    end
  end

  def cancelmultiple
    @appointmentlist = Appointment.where(:id.in => (params[:appointment][:appointmentidsarray]).to_s.split(',').collect(&:to_s))
    respond_to do |format|
      format.js {}
    end
  end

  def cancelmultiple_save
    @appointments_list = Appointment.where(:id.in => params[:appointmentid].to_a.collect(&:to_s))
    @appointments_list.each do |appointment|
      appointment.update_attributes({ appointmentstatus: 89925002 })
    end

    respond_to do |format|
      format.js {}
    end
  end

  def searchpatient
    # current_facility_array
    r_query = params[:q].split(' ').join('.*')
    # @patientlist = Patient.where(reg_hosp_ids: current_user.organisation_id.to_s, "$or" => [{mobilenumber: /#{Regexp.escape(params[:q])}/i}, {secondarymobilenumber: /#{Regexp.escape(params[:q])}/i}, {fullname: /#{Regexp.escape(params[:q])}/i}, {:id.in => PatientOtherIdentifier.where(mr_no: /#{Regexp.escape(params[:q])}/i).pluck(:patient_id)}]).uniq
    @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, search: /#{r_query}/i).limit(10)
  end

  def searchpatientresultfocus
    @user = current_user
    @date = Date.current
    @patient = Patient.find(params[:searchresultfocus][:patientid])
    @patient_ident = PatientOtherIdentifier.find_by(patient_id: params[:searchresultfocus][:patientid])
    current_facility_array
    @facility_id = current_facility.id
    @facilities = Common.new.fetch_facilities(user: current_user)
    @departments = Common.new.fetch_departments(facilities: @facilities)

    # inacase of doctor_signin only doctor's name and doctor's appointment type should be seen.
    if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
      @users = []
      @users << current_user
      @appointment_types = AppointmentType.where(user_id: current_user.id, is_active: true)
    else
      @users = Common.new.fetch_users(org_type: current_user.organisation.type, organisation_id: current_user.organisation.id, facility_id: current_facility.id, department_id: @departments.first.id)
      @appointment_types = AppointmentType.where(user_id: @users.first.id, is_active: true)
    end

    respond_to do |format|
      format.js {}
    end
  end

  def searchpatientresultselect
    current_facility_array
    @date = Time.current
    @user = User.where(:role_ids.in => [158965000], :facility_ids.in => [current_facility.id])[0]
    @appointment_date = params[:appointment_date]
    @start_time = params[:start_time]
    @end_time = params[:end_time]
    @patient = Patient.find(params[:searchresultselect][:patientid])
    @patient_pastappointments = Appointment.where(patient_id: @patient.id).order(appointmentdate: :asc, appointmenttime: :asc).limit(2)
    @patient_ident = PatientOtherIdentifier.find_by(patient_id: params[:searchresultselect][:patientid])
    @facilities = Common.new.fetch_facilities(user: current_user)
    @departments = Common.new.fetch_departments(facilities: @facilities)

    if params[:current_doctor]
      @current_doctor = if params[:current_doctor] == 'all'
                          ''
                        else
                          User.where(id: params[:current_doctor]).pluck(:fullname, :id).first
                        end
      # p @current_doctor
    end

    # inacase of doctor_signin only doctor's name and doctor's appointment type should be seen.
    if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
      @users = []
      @users << current_user
      @appointment_types = AppointmentType.where(user_id: current_user.id, is_active: true)
    else
      @users = Common.new.fetch_users(org_type: current_user.organisation.type, organisation_id: current_user.organisation.id, facility_id: current_facility.id, department_id: @departments.first.id)
      @appointment_types = AppointmentType.where(user_id: @users.first.id, is_active: true)
    end

    @facility_id = current_facility.id

    respond_to do |format|
      format.js {}
    end
  end

  def holiday
    @appointment_eventid = params[:appointment][:eventid]
    @appointment_date = params[:appointment][:start]
    respond_to do |format|
      format.js {}
    end
  end

  def setoutofoffice
    @outofoffice = Outofoffice.new(setoutofoffice_params)
    @outofoffice.save
    respond_to do |format|
      format.js {}
    end
  end

  def daylistjson # not in use
    appointmentdate = Date.strptime((params[:appointmentdaylist][:appointmentdate]).to_s, '%d/%m/%Y').strftime('%Y-%m-%d')
    if params[:appointmentdaylist][:department_id].to_i == 0
      department_ids = current_facility.department_ids

      options = { :appointmentdate => appointmentdate, :department_id.in => department_ids, :facility_id => current_facility.id, :appointmentstatus.in => [416774000, 58334001] }
    else
      options = { :appointmentdate => appointmentdate, :department_id => params[:appointmentdaylist][:department_id], :facility_id => current_facility.id, :appointmentstatus.in => [416774000, 58334001] }
    end

    if params[:appointmentdaylist][:user_id].to_i != 0
      options = options.merge({ user_id: params[:appointmentdaylist][:user_id] })
    end
    @appointmentdaylist = Appointment.where(options).order(appointmenttime: :asc)
    respond_to do |format|
      # format.json { render :json => @appointmentdaylist }
      format.html { render layout: false }
    end
  end

  def daylisthoverin
    appointmentdate = Date.strptime((params[:appointmentdaylist][:appointmentdate]).to_s, '%d/%m/%Y').strftime('%Y-%m-%d')
    @appointmentdaylist_hoverin = Appointment.where(appointmentdate: appointmentdate.to_s).order(appointmenttime: :asc)
    respond_to do |format|
      format.js {}
    end
  end

  def daylisthoverout
    respond_to do |format|
      format.js {}
    end
  end

  def calendar_appointment_data
    doctor_id = params[:doctor_id]
    # facility = Facility.find(params[:facility_id])
    facility = current_facility
    if params[:department_id].to_i == 0
      department_ids = facility.department_ids
      options = { :facility_id => facility.id, :department_id.in => department_ids, :appointmentstatus.in => [416774000, 58334001] }
    else
      options = { :facility_id => facility.id, :department_id => params[:department_id].to_s, :appointmentstatus.in => [416774000, 58334001] }
    end

    options = options.merge({ consultant_id: params[:user_id] }) if params[:user_id].present? && params[:user_id].to_i != 0

    # unless doctor_id.nil? || doctor_id == ""
    #   options = options.merge({ doctor: doctor_id })
    # else
    #   unless doctor_id == "all"
    #     options = options.merge({doctor: params[:user_id]})
    #   end
    # end

    if params[:doctor_id].nil? || params[:doctor_id] == ''
      options = options.merge({ consultant_id: params[:user_id] })
    elsif params[:doctor_id] == 'all'
      # Do nothing
    else
      options = options.merge({ consultant_id: params[:doctor_id] })
    end

    @appointment_list = Appointment.where(options).between(appointmentdate: Date.parse(params[:start])..Date.parse(params[:end]))

    @total_appointment_count = Appointment.where(options).count

    respond_to do |format|
      format.json {}
    end
  end

  def calendar_appointment_details
    # Kumar Abinash
    # => Renders modal with appointmet details in calendar view
    @newcounsellornote = CounsellorNote.new
    @showcounsellornote = CounsellorNote.where(organisation_id: current_user.organisation_id).order(created_at: :desc)
    @newpatientnote = PatientNote.new
    @showpatientnote = PatientNote.where(organisation_id: current_user.organisation_id).order(created_at: :desc)
    @appointment = Appointment.find_by(id: params[:appointment_id])

    # @appointment = Appointment.find(params[:appointment_id])

    @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, version: 'v21.0')
    @cash_register_templates = CashRegisterTemplate.where(user_id: current_user.id)
    @source = 'calendar'
    if current_facility.clinical_workflow
      @pat_workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
      states = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @pat_workflow.id).pluck(:to)
      @with_user = User.find_by(id: @pat_workflow.user_id)
      @states = states.map(&:capitalize)

    end
    @advance = AdvancePayment.where(patient_id: @appointment.patient_id, type: 'OPD', advance_state: 'None')
    # if DocReminderNote.find_by(patient_id: @appointment.patient.id.to_s) == nil
    #   @reminder_text = ""
    # else
    #   @reminder_text = DocReminderNote.find_by(patient_id: @appointment.patient.id.to_s).reminder_text
    # end

    @patient = Patient.find(@appointment.patient.id.to_s)
    @eyedrop_allergy = []
    if @patient.patient_history.patientallergyhistory.eyedrops.present?
      @patient.patient_history.patientallergyhistory.eyedrops.each do |eyedrops|
        @eyedrop_allergy.push(@patient.get_label_for_allergy('eyedrops', eyedrops))
      end
    end

    @all_current_facility_users = current_user.organisation.users.where(:facility_ids.in => [current_facility.id]) - [current_user]
    @current_facility_doctors = current_user.organisation.users.where(:facility_ids.in => [current_facility.id], :role_ids.in => [158965000])
    @current_facility_optometrist = current_user.organisation.users.where(:facility_ids.in => [current_facility.id], :role_ids.in => [28229004])
    @current_facility_lab_technician = current_user.organisation.users.where(:facility_ids.in => [current_facility.id], :role_ids.in => [159282002])
    @current_facility_receptionists = current_user.organisation.users.where(:facility_ids.in => [current_facility.id], :role_ids.in => [159561009])
    @current_facility_counsellor = current_user.organisation.users.where(:facility_ids.in => [current_facility.id], :role_ids.in => [499992366])
    respond_to do |format|
      format.html { render partial: 'opd_appointments/calendar/calendar_appointment_details', layout: false }
    end
  end

  def calendar_appointment_week_data
    # facility = Facility.find(params[:facility_id])
    facility = current_facility
    if params[:department_id].to_i == 0
      department_ids = facility.department_ids
      options = { :facility_id => facility.id, :department_id.in => department_ids, :appointmentstatus.in => [416774000, 58334001, 89925002] }
    else
      options = { :facility_id => facility.id, :department_id => params[:department_id], :appointmentstatus.in => [416774000, 58334001, 89925002] }

    end

    options = options.merge({ user_id: params[:user_id] }) if params[:user_id].present? && params[:user_id].to_i != 0
    @appointment_list = Appointment.where(options).between(appointmentdate: Date.parse(params[:start])..Date.parse(params[:end]))

    @total_appointment_count = Appointment.where(options).count
    respond_to do |format|
      format.json {}
    end
  end

  # function responsible for rearranging event and resizing event on calendar screen
  # Should render back the updated events timings.
  def edit_calendar_event
    appointment = Appointment.find(params[:appointment_id])
    appointment.update_attributes(appointmentdate: Date.parse(params['appointment_new_start']), start_time: Time.zone.parse(params['appointment_new_start']), end_time: Time.zone.parse(params['appointment_new_end']))

    # facility = appointment.facility_id
    # department_id = appointment.department_id
    # user_id = appointment.user_id
    # options = {:facility_id => facility.id,:department_id => department_id, :appointmentstatus.in => [416774000, 58334001], :user_id => user_id}

    # # if params[:user_id].present? && params[:user_id].to_i !=0
    # #   options = options.merge({:user_id => params[:user_id]})
    # # end
    # @appointment_list = Appointment.where(options).between(:appointmentdate => Date.parse(params[:start])..Date.parse(params[:end]))

    # @total_appointment_count = Appointment.where(options).count

    # respond_to do |format|
    #   format.json {}
    # end
  end

  def has_arrived
    appointment_id = params[:appointment_id]
    @appointment = Appointment.find(appointment_id)
    @appointment.patient_arrived
    arrived_time = Time.current
    @appointment.update({ arrived: true, seen: false, arrived_time: arrived_time })
    # SmsJob.perform_later("visit_sms",appointment_id)
    # patient_visit = PatientVisit.find_by(:patient_id => @appointment.patient.id.to_s, :encounter_date => Date.current)
    # if !patient_visit.nil?
    #   patient_visit.update_attributes(:encounter_date => Date.current)
    # else
    #     PatientVisit.create(:doctor => @appointment.doctor.to_s, :encounter_date => Date.current, :encounter_type => "OPD", :patient_id => @appointment.patient.id.to_s, :organisation_id => current_user.organisation.id.to_s, :facility_id => @appointment.facility.id.to_s, :user_id => current_user.id.to_s)
    # end
    respond_to do |format|
      # format.js { } #JS template used while using datatables
      format.js { render js: '' }
    end
  end

  def undo_arrived
    # Kumar Abinash
    # Marks appointment scheduled from waiting, incase user accidentally marked appoitnment waiting
    @appointment = Appointment.find(params[:appointment_id])
    @appointment.undo_arrived

    # remove arrived time
    # @appointment.remove_attribute(:arrived_time)

    @appointment.update({ arrived: false, seen: false, arrived_time: nil })
    # patient_visit = PatientVisit.find_by(:patient_id => @appointment.patient.id.to_s, :encounter_date => Date.current)
    # if !patient_visit.nil?
    #   patient_visit.update_attributes(:encounter_date => Date.current)
    # else
    #     PatientVisit.create(:doctor => @appointment.doctor.to_s, :encounter_date => Date.current, :encounter_type => "OPD", :patient_id => @appointment.patient.id.to_s, :organisation_id => current_user.organisation.id.to_s, :facility_id => @appointment.facility.id.to_s, :user_id => current_user.id.to_s)
    # end
    respond_to do |format|
      # format.js { render js: "fetchAppointmentData();"}
      format.js { render js: '' }
    end
  end

  # def has_engaged
  #   appointment_id = params[:appointment][:appointment_id]
  #   @appointment = Appointment.find(appointment_id)
  #   @appointment.patient_engaged
  #   if @appointment.arrived_time.nil?
  #     @appointment.update({:arrived_time => @appointment.start_time - 300})
  #   end
  #   arrived_time = @appointment.arrived_time
  #   engage_time = Time.current
  #   waiting_time_min = ( (engage_time - arrived_time) / 60 ).ceil
  #   if waiting_time_min <= 0
  #     waiting_time_min = 1
  #   end
  #   @appointment.update({:engaged => true,:arrived => true, :seen => false, :engage_time => engage_time, :waiting_time_min =>  waiting_time_min})
  #   patient_visit = PatientVisit.find_by(:patient_id => @appointment.patient.id.to_s, :encounter_date => Date.current)
  #   if !patient_visit.nil?
  #     patient_visit.update_attributes(:encounter_date => Date.current)
  #   else
  #     PatientVisit.create(:doctor => @appointment.doctor.to_s, :encounter_date => Date.current, :encounter_type => "OPD", :patient_id => @appointment.patient.id.to_s, :organisation_id => current_user.organisation.id.to_s, :facility_id => @appointment.facility.id.to_s, :user_id => current_user.id.to_s)
  #   end
  #   respond_to do |format|
  #     # format.js { } #JS template used while using datatables
  #     format.js { render js: "" }
  #   end
  # end

  def has_seen
    appointment_id = params[:appointment_id]
    @appointment = Appointment.find(appointment_id)
    @appointment.patient_seen
    if @appointment.arrived_time.nil?
      @appointment.update({ arrived_time: @appointment.start_time - 300, waiting_time_min: 10 })
    end
    @appointment.update({ engage_time: @appointment.start_time + 300 }) if @appointment.engage_time.nil?
    arrived_time = @appointment.arrived_time
    engage_time = @appointment.engage_time
    seen_time = Time.current
    engaged_time_min = ((seen_time - engage_time) / 60).ceil
    total_time_min = ((seen_time - arrived_time) / 60).ceil
    waiting_time_min = ((engage_time - arrived_time) / 60).ceil
    waiting_time_min = 1 if waiting_time_min <= 0
    engaged_time_min = waiting_time_min if engaged_time_min <= 0
    total_time_min = waiting_time_min if total_time_min <= 0
    @appointment.update({ engaged: false, seen: true, arrived: true, seen_time: seen_time, engaged_time_min: engaged_time_min, total_time_min: total_time_min, waiting_time_min: waiting_time_min })
    patient_visit = PatientVisit.find_by(patient_id: @appointment.patient.id.to_s, encounter_date: Date.current)
    if !patient_visit.nil?
      patient_visit.update_attributes(encounter_date: Date.current)
    else
      PatientVisit.create(doctor: @appointment.consultant_id.to_s, encounter_date: Date.current, encounter_type: 'OPD', patient_id: @appointment.patient.id.to_s, organisation_id: current_user.organisation.id.to_s, facility_id: @appointment.facility.id.to_s, user_id: current_user.id.to_s)
    end
    @patient_visit_id = PatientVisit.find_by(patient_id: @appointment.patient.id.to_s, encounter_date: Date.current).id

    # Kumar Abinash
    @appointment.update_attributes(dilation_end_time: Time.current) if @appointment.dilation_start_time
    # VisitSmsJob.set(wait: 1.hour).perform_later(@patient_visit_id.to_s)
    respond_to do |format|
      # format.js { } #JS template used while using datatables
      format.js { render js: '' }
    end
  end

  def get_booked_appointments
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    facility_id =  params[:facility_id].present? ? params[:facility_id] : current_facility.id
    @appointment = Appointment.where(created_at: @date.midnight..@date.end_of_day, consultant_id: params[:doctor_id], facility_id: facility_id, specialty_id: params[:specialty_id])
    @user = User.find_by(id: params[:doctor_id])
    @doctors = User.where(organisation_id: current_user.organisation_id, facility_ids: facility_id, specialty_ids: params[:specialty_id], :role_ids.in => current_facility['consultant_role_ids'], is_active: true).pluck(:fullname, :id).to_json

    @appointment_types = AppointmentType.where(facility_id: facility_id, specialty_ids: params[:specialty_id], is_active: true)
    unless @appointment_types.present?
      @appointment_types = AppointmentType.where(user_id: @user.try(:id), specialty_ids: params[:specialty_id], is_active: true)
    end

    @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: current_user.organisation_id, specialty_ids: params[:specialty_id], is_active: true).order(created_at: :desc).pluck(:label, :id).to_json

    @opdrecord = OpdRecord.find_by(id: params[:opdrecord_id]) if params[:opdrecord_id].present?
    @facility_id = facility_id.to_s
    @flag = params[:flag]
    respond_to do |format|
      format.js {}
    end
  end

  def surgery_advised
    @appointment = Appointment.find_by(id: params[:id])
    @state = params[:state]
    @appointment.update_attributes(surgery_advised: @state)

    render json: { surgery_advised: @appointment.surgery_advised }
  end

  def user_time_slot_check
    organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    user_time_slot = UserTimeSlot.find_by(user_id: params[:doctor_id])
    if organisation_setting.time_slots_enabled && user_time_slot
      options = { department_id: params[:department_id], facility_id: params[:facility_id] }

      opd_sessions = user_time_slot.sessions.where(options)
      opd_exception_sessions = user_time_slot.exception_sessions.where(options)

      opd_slots_present = (opd_sessions.count > 0 || opd_exception_sessions.count > 0)
    else
      opd_slots_present = false
    end

    render json: opd_slots_present
  end

  def calendar_time_slot
    @consultant_id = params[:doctor_id]
    @facility_id = params[:facility_id]
    @department_id = params[:department_id]
    @user_time_slot = UserTimeSlot.includes(:user).find_by(user_id: @consultant_id)
  end

  private

  def set_update_analytics_params
    @analytics_params = {}
    @patient_referral_type = PatientReferralType.find_by(appointment_id: @appointment.id)
    @analytics_params['appointment_id'] = @appointment.id
    @analytics_params['patient_referral_id'] = @patient_referral_type.try(:id)
    @analytics_params['before_referral_type_id'] = (if @patient_referral_type.try(:is_deleted) == false
                                                      @patient_referral_type.try(:referral_type_id)
                                                    end) || nil
    @analytics_params['before_appointment_date'] = @appointment.appointmentdate
    @analytics_params['before_facility_id'] = @appointment.facility_id
  end

  def current_facility_array
    @facilities = Common.new.fetch_facilities(user: current_user)
    @current_facility_array = []
    @facilities_array = @facilities.map { |facility| [facility.name, facility.id] }

    if current_user.facilities.count > 1
      get_schedule_time_for_current_user
      @facilities_array.each do |facility|
        next unless facility[1].to_s == @current_facility_id.to_s

        @current_facility_array = []
        @current_facility_array.push(facility)
        break
      end
    end

    unless @current_facility_array.present?
      @current_facility_array = []
      @current_facility_array.push(@facilities_array[0])
    end
  end

  def next_followup_date(followup_advice, appointment_date)
    appointment_date_format = Date.parse(appointment_date, '%d-%b-%Y')

    if followup_advice['displayname'] == 'Immediate'
      appointment_date_format
    elsif followup_advice['displayname'] == '2-3 D'
      appointment_date_format + 3.days
    elsif followup_advice['displayname'] == '4-6 D'
      appointment_date_format + 5.days
    elsif followup_advice['displayname'] == '1 W'
      appointment_date_format + 7.days
    elsif followup_advice['displayname'] == '2 W'
      appointment_date_format + 14.days
    elsif followup_advice['displayname'] == '3 W'
      appointment_date_format + 21.days
    elsif followup_advice['displayname'] == '6 W'
      appointment_date_format + 42.days
    elsif followup_advice['displayname'] == '2-3 M'
      appointment_date_format + 90.days
    elsif followup_advice['displayname'] == '6 M'
      appointment_date_format + 180.days
    elsif followup_advice['displayname'] == '1 Y'
      appointment_date_format + 365.days
    elsif followup_advice['displayname'] == 'SOS'
      Time.current
    end
  end

  def edit_appointment_params
    params.permit(:appointmentdate, :start_time, :end_time).merge(appointmentstatus: 58334001)
  end

  def cancel_appointment_params
    params.permit(:appointmentdate, :appointmenttime).merge(appointmentstatus: 58334001)
  end

  def today_date
    @datepicker_date = Date.current.strftime('%Y-%m-%d').to_s
  end

  def setoutofoffice_params
    params.permit(:reasonoutofoffice, :fromoutofofficedate, :fromoutofofficetime,
                  :tooutofofficedate, :tooutofofficetime).merge(outofofficeid: _outofofficeid)
  end

  def schedule_timeline(facility, user)
    start_time = ''
    end_time = ''
    current_schedule = UsersSetting.find_by(organisation_id: current_user.organisation_id, facility_id: facility.id, user_id: user)
    if current_schedule.nil?
      current_schedule = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    end
    current_schedule.weekday_setting.each do |_index, each_day|
      each_day.each do |_count, each_schedule|
        start_time = each_schedule[:from] if (start_time == '') || (start_time > each_schedule[:from])
        end_time = each_schedule[:to] if (end_time == '') || (end_time < each_schedule[:to])
      end
    end
    [start_time, end_time]
  end

  # for sigining up patient while creating appointment
  # def appointment_patient_create_params
  #   params.require(:patient).permit(:fullname,:firstname,:lastname, :gender,:dob, :age, :mobilenumber, :secondarymobilenumber, :email, :blood_group,:address_1,:address_2,:city,:state,:pincode,:emergencycontactname, :emergencymobilenumber, :maritalstatus, :specialstatus, :occupation, :reg_date, :reg_time, :reg_hosp_ids => [], appointments_attributes: [:appointment_type_id,:display_id, :appointmentdate, :start_time,:end_time,:departmenttype,:appointmentstatus, :user_id,:department_id, :facility_id,:doctor,:ref_doc_name,:ref_doc_place],patientassets_attributes: [:asset_path],patient_history_attributes: [ :patient_id, :patientid, :templatetype, :templateid, patientpersonalhistory_attributes: [:flag,problems: []], patientallergyhistory_attributes: [:flag,:others, antimicrobialagents: [], nsaids: [], antifungalagents: [], antiviralagents: [], contact: [], food: [],eyedrops: [] ] ])
  # end

  def appointment_patient_create_params
    params.require(:patient)
  end

  def nil_patientpersonalhistory_params
    params.require(:patient_history).permit(patientpersonalhistory_attributes: [problems: ['100005']])
  end

  def start_cinical_workflow
    patient = Patient.find_by(id: @appointment.patient_id)
    OpdClinicalWorkflow.create(patient_id: @appointment.patient_id, appointment_id: @appointment.id.to_s, facility_id: @appointment.facility_id, organisation_id: current_user.organisation.id, user_id: current_user.id, appointmentdate: @appointment.appointmentdate, specialty_id: @appointment.specialty_id, department_id: @appointment.department_id, consultant_ids: [@appointment.consultant_id.to_s])
  end

  def patient_note_params
    params.permit(:comment, :creation_date, :completion_date, :user_id, :organisation_id, :is_complete, :patient_id)
  end

  def setup_data_for_counsellor
    @my_queue = OpdClinicalWorkflow.where(organisation_id: current_user.organisation_id, appointmentdate: @datepicker_date, facility_id: current_facility.id.to_s, :state.nin => ['cancelled'], state: 'counsellor').order('start_time DESC')
    @today_patient = CounsellorWorkflow.where(organisation_id: current_user.organisation_id, appointmentdate: @datepicker_date, facility_id: current_facility.id.to_s).order('start_time ASC')
    @counsellor_appointments = CounsellorWorkflow.where(organisation_id: current_user.organisation_id, counsellingdate: @datepicker_date, facility_id: current_facility.id.to_s).order('start_time ASC')
    @followup = @counsellor_appointments.where(state: 'followup')
    @surgery = @counsellor_appointments.where(state: 'converted')
    @cancelled = @today_patient.where(state: 'cancelled').order('start_time ASC')
    @upcoming = CounsellorWorkflow.where(organisation_id: current_user.organisation_id, :counsellingdate.gt => @datepicker_date, facility_id: current_facility.id.to_s, :state.nin => ['converted', 'cancelled']).order('start_time DESC')
  end

  def reset_token
    @token_setting = TokenSetting.find_by(facility_id: @appointment.facility_id)

    key = "used_tokens:#{@appointment.facility_id}:#{@appointment.appointmentdate.strftime('%d%m%Y')}"
    # @used_tokens = $REDIS.get("used_tokens:#{@appointment.facility_id.to_s}:#{Date.current.strftime('%d%m%Y')}") || "{}"
    @used_tokens = Redis::Master.new.get(key) || '{}'
    if @used_tokens == '{}'
      @used_tokens = @token_setting.used_tokens.to_json if @token_setting.try(:used_tokens).present?
    end
    @new_used_tokens = JSON.parse(@used_tokens)

    @new_used_tokens.delete(@appointment.token_number)

    # @appointment.update(token_number: nil) if @appointment.present?

    # $REDIS.set("used_tokens:#{@appointment.facility_id.to_s}:#{@appointment.appointmentdate.strftime('%d%m%Y')}", @new_used_tokens.to_json)
    Redis::Master.new.set(key, @new_used_tokens.to_json)
    Redis::Master.new.expireat(key, ((Date.current + 1).to_time + 2.hours).to_i)

    if @token_setting.present? && @appointment.appointmentdate == Date.current
      @token_setting.update(used_tokens: @new_used_tokens)
    end
  end

  def remove_redis_workflow_qm(workflow)
    date = Date.today.strftime('%d%m%Y')
    facility_id = workflow.facility_id

    # Reference Key for ZADD & HMSET
    patient_key = "qm:facility:#{facility_id}:date:#{date}:patient_id:#{workflow.patient_id}"

    # ZADD Area Key
    zadd_area_key = "qm:facility:#{facility_id}:date:#{date}:area_id:#{workflow.area_id}"
    $REDIS.zrem zadd_area_key, patient_key

    # ZADD Station Key
    zadd_station_key = "qm:facility:#{facility_id}:date:#{date}:station_id:#{workflow.station_id}"
    $REDIS.zrem zadd_station_key, patient_key

    ActionCable.server.broadcast("remove_queue_#{workflow.station_id}_channel", workflow_id: workflow.id.to_s)
    ActionCable.server.broadcast("remove_queue_#{workflow.area_id}_channel", workflow_id: workflow.id.to_s)
  end
end
