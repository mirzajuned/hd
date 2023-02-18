class IpdPatientsController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  layout 'loggedin'

  # Show Datatable related data on load page ipd admission

  def test_graph
    @patient = Patient.where(:age.nin => [nil])
  end

  def home
    @ipd_path = 'Admission'
    @current_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y') : Date.parse(Date.current.to_s, '%d-%B-%Y')
    @datepicker_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s : Date.parse(Date.current.to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s
    current_facility_array

    if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      @users_array = [[current_user.fullname, current_user.id]]

    else
      # @departments = Common.new.fetch_departments(:facilities => @facilities)                         for now in case of nurse only her department is needed
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      # @users = Common.new.fetch_users(:org_type => current_user.organisation.type,:organisation_id => current_user.organisation.id,:facility_id => current_facility.id,:department_id => @departments.first.id)
      @users = User.where(facility_ids: current_facility.id.to_s, role_ids: 158965000)
      @users_array = @users.map { |user| [user.fullname, user.id] }
      @users_array = [['All Users', '0']] + @users_array
    end

    user_default_slot = AppointmentType.find_by(user_id: @users_array[0][1], is_default: true, is_active: false)
    @user_default_slot_time = if user_default_slot
                                user_default_slot.duration
                              else
                                15
                              end

    @admission_all = if current_user.role_ids[0] == 106292003 || current_user.role_ids[0] == 159561009
                       Admission.where(facility_id: current_facility.id.to_s, is_deleted: false)
                     else
                       Admission.where(facility_id: current_facility.id.to_s, doctor: current_user.id.to_s, is_deleted: false)
                     end

    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  def ot_management
    @ipd_path = 'OT'
    @current_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y') : Date.parse(Date.current.to_s, '%d-%B-%Y')
    @datepicker_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s : Date.parse(Date.current.to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s
    current_facility_array

    if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      @users_array = [[current_user.fullname, current_user.id]]

    else
      # @departments = Common.new.fetch_departments(:facilities => @facilities)                         for now in case of nurse only her department is needed
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      # @users = Common.new.fetch_users(:org_type => current_user.organisation.type,:organisation_id => current_user.organisation.id,:facility_id => current_facility.id,:department_id => @departments.first.id)
      @users = User.where(facility_ids: current_facility.id.to_s, role_ids: 158965000)
      @users_array = @users.map { |user| [user.fullname, user.id] }
      @users_array = [['All Users', '0']] + @users_array
    end

    user_default_slot = AppointmentType.find_by(user_id: @users_array[0][1], is_default: true, is_active: false)
    @user_default_slot_time = if user_default_slot
                                user_default_slot.duration
                              else
                                15
                              end

    @admission_all = if current_user.role_ids[0] == 106292003 || current_user.role_ids[0] == 159561009
                       Admission.where(facility_id: current_facility.id.to_s, is_deleted: false)
                     else
                       Admission.where(facility_id: current_facility.id.to_s, doctor: current_user.id.to_s, is_deleted: false)
                     end

    respond_to do |format|
      format.js { render 'home.js.erb', layout: false }
      format.html { render 'home.html.erb' }
    end
  end

  def ward_management
    @ipd_path = 'Ward'
    @current_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y') : Date.parse(Date.current.to_s, '%d-%B-%Y')
    @datepicker_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s : Date.parse(Date.current.to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s
    current_facility_array

    if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      @users_array = [[current_user.fullname, current_user.id]]

    else
      # @departments = Common.new.fetch_departments(:facilities => @facilities)                         for now in case of nurse only her department is needed
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      # @users = Common.new.fetch_users(:org_type => current_user.organisation.type,:organisation_id => current_user.organisation.id,:facility_id => current_facility.id,:department_id => @departments.first.id)
      @users = User.where(facility_ids: current_facility.id.to_s, role_ids: 158965000)
      @users_array = @users.map { |user| [user.fullname, user.id] }
      @users_array = [['All Users', '0']] + @users_array
    end

    user_default_slot = AppointmentType.find_by(user_id: @users_array[0][1], is_default: true, is_active: false)
    @user_default_slot_time = if user_default_slot
                                user_default_slot.duration
                              else
                                15
                              end

    @admission_all = if current_user.role_ids[0] == 106292003 || current_user.role_ids[0] == 159561009
                       Admission.where(facility_id: current_facility.id.to_s, is_deleted: false)
                     else
                       Admission.where(facility_id: current_facility.id.to_s, doctor: current_user.id.to_s, is_deleted: false)
                     end

    respond_to do |format|
      format.js { render 'home.js.erb', layout: false }
      format.html { render 'home.html.erb' }
    end
  end

  # Show Datatable related data on load page ipd ot
  def otschedule
    @current_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y') : Date.parse(Date.current.to_s, '%d-%B-%Y')
    @datepicker_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s : Date.parse(Date.current.to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s
    current_facility_array

    if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      @users_array = [[current_user.fullname, current_user.id]]

    else
      # @departments = Common.new.fetch_departments(:facilities => @facilities)                         for now in case of nurse only her department is needed
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      # @users = Common.new.fetch_users(:org_type => current_user.organisation.type,:organisation_id => current_user.organisation.id,:facility_id => current_facility.id,:department_id => @departments.first.id)
      @users = User.where(facility_ids: current_facility.id.to_s, role_ids: 158965000)
      @users_array = @users.map { |user| [user.fullname, user.id] }
      @users_array = [['All Users', '0']] + @users_array
    end

    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  # Show Datatable related data on Change Date page ipd admission
  def admissionschedule
    @current_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y') : Date.parse(Date.current.to_s, '%d-%B-%Y')
    @datepicker_date = params[:admission_day] ? Date.parse(params[:admission_day].to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s : Date.parse(Date.current.to_s, '%d-%B-%Y').strftime('%Y-%m-%d').to_s

    current_facility_array
    if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      @users_array = [[current_user.fullname, current_user.id]]

    else
      # @departments = Common.new.fetch_departments(:facilities => @facilities)                         for now in case of nurse only her department is needed
      # @departments =Array.new
      # @departments << Department.find_by(id: current_user.department_id)
      # @users = Common.new.fetch_users(:org_type => current_user.organisation.type,:organisation_id => current_user.organisation.id,:facility_id => current_facility.id,:department_id => @departments.first.id)
      @users = User.where(facility_ids: current_facility.id.to_s, role_ids: 158965000)
      @users_array = @users.map { |user| [user.fullname, user.id] }
      @users_array = [['All Users', '0']] + @users_array
    end

    # if current_user.role_ids[0] == 106292003 || current_user.role_ids[0] == 159561009
    #   @admission = Admission.where(facility_id: current_user.facility_ids[0].to_s)
    # else
    #   @admission = Admission.where(facility_id: current_user.facility_ids[0].to_s, doctor: current_user.id.to_s)
    # end

    if params[:doctor] == 'all' || params[:doctor].nil?
      @admission_all = Admission.where(facility_id: current_facility.id.to_s, is_deleted: false)
      @doctor = 'all'
    else
      @admission_all = Admission.where(facility_id: current_facility.id.to_s, doctor: params[:doctor], is_deleted: false)
      @doctor = params[:doctor]
    end

    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  # Datatable Logic
  def home_data
    facility = Facility.find(params[:facility_id])
    if params[:department_id].to_i == 0
      if Date.current.strftime('%Y-%m-%d') == params[:current_date]
        options = { :facility_id => facility.id, :admissiondate.gte => current_user.organisation.created_at, :admissiondate.lt => Date.current + 1, '$or' => [{ dischargedate: Date.current }, { isdischarged: false }] }
      else
        options = { admissiondate: params[:current_date], facility_id: facility.id }
      end
    else
      if Date.current.strftime('%Y-%m-%d') == params[:current_date]
        options = { :facility_id => facility.id, :admissiondate.gte => current_user.organisation.created_at, :admissiondate.lt => Date.current + 1, '$or' => [{ dischargedate: Date.current }, { isdischarged: false }] }

      else
        options = { admissiondate: params[:current_date], facility_id: facility.id }
      end
    end

    options = options.merge(doctor: params[:doctor]) if params[:doctor].present? && params[:doctor].to_i != 0
    @admission_list = Admission.all_of(options).order(admissiondate: :desc)
    # Admission.where(options).order("start_time "+params[:sSortDir_0])
    @total_admission_count = Admission.where(options).count

    if params[:sSearch] != ''
      patients_list = @admission_list.map(&:patient_id)
      letter = params[:sSearch]
      capital_letter = letter.try(:capitalize)
      all_capital_letter = letter.try(:upcase)
      patients_final_list = Patient.where(:id.in => patients_list, :fullname => /^#{letter}|#{capital_letter}|#{all_capital_letter}/).map(&:_id)
      options = options.merge(:patient_id.in => patients_final_list)
      @admission_list = Admission.where(options)
                                 .order('start_time ' + params[:sSortDir_0])
    end
    @admission_list_count = Admission.where(options).count

    @sEcho = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  # OT Datatable Logic
  def ot_schedule
    facility = Facility.find(params[:facility_id])
    options = if params[:department_id].to_i == 0
                { otdate: params[:current_date], facility_id: facility.id }
              else
                { otdate: params[:current_date], facility_id: facility.id }
              end
    if params[:surgeonname].present? && params[:surgeonname].to_i != 0
      options = options.merge(surgeonname: params[:surgeonname])
    end
    @ot_list = OtSchedule.where(options)
    @total_admission_count = OtSchedule.where(options).count
    @admission_list_count = OtSchedule.where(options).count

    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  # Bed Datatable Logic
  def bedsmanagement_schedule
    @sEcho = params[:sEcho]
    facility = Facility.find(params[:facility_id])
    options = if params[:department_id].to_i == 0
                { organisation_id: params[:organisation_id], facility_id: params[:facility_id] }
              else
                { organisation_id: params[:organisation_id], facility_id: params[:facility_id] }
              end
    @ward_list = Ward.where(options)
    @ward_list_count = @ward_list.count
    @total_ward_list_count = @ward_list.count
    respond_to do |format|
      format.json {}
    end
  end

  # ?
  def beds_layout
    respond_to do |format|
      format.js {}
    end
  end

  # Make New Admission
  def makeadmission
    respond_to do |format|
      format.js {}
    end
  end

  # Print Admission List
  def printadmission
    @datepicker_date = Date.parse(params[:admissiondate].to_s, '%d-%b-%Y').strftime('%Y-%m-%d').to_s
    @organisation = current_user.organisation
    @facility = Facility.find_by(id: params[:facility_id])
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'ipd_patients/admissionlist_print', pdf: 'AdmissionList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  # Print Admission List By Facility on dashboard
  def printadmission_by_facility
    @organisation = current_user.organisation
    @facility = Facility.find_by(id: params[:facility_id])
    @user = User.find_by(id: params[:doctor])
    if [[158965000], [158965000, 6868009]].include? current_user.role_ids
      @admission = Admission.where(admissiondate: Date.current, facility_id: @facility.id, doctor: current_user.id)
    else
      @admission = if @user.nil?
                     Admission.where(admissiondate: Date.current, facility_id: @facility.id)
                   else
                     Admission.where(admissiondate: Date.current, facility_id: @facility.id, doctor: @user.id)
                   end
    end
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'ipd_patients/partials/admissionlist_dashboard.pdf.erb', pdf: 'AdmissionList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  # Removed Mohit
  def printdischarge_list
    # @organisation = current_user.organisation
    # @facilty = Facility.find_by(:organisation_id => current_user.organisation)
    # @admission = Admission.where(:isdischarged => true, :user_id => current_user.id).order(facility_id: :asc)
    # respond_to do |format|
    #   format.pdf {render :template => "ipd_patients/dischargelist_print.pdf.erb", :pdf => "Dischargelist", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => {:spacing => 10,:html => {:template => 'layouts/pdf-header.html'}},:footer => {:html => { :template=>  'layouts/pdf-footer.html' },:spacing => 10, }, :margin => {:top=> @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom => 40 } }
    # end
  end

  # Removed Mohit
  def printdischarge_list_by_facility
    # @organisation = current_user.organisation
    # @facilty = Facility.find_by(:id => params[:facility_id])
    # if [[158965000],[158965000,6868009]].include? current_user.role_ids
    #   @admission = Admission.where(:facility_id => @facilty.id, :isdischarged => true, :doctor => current_user.id).order(dischargetime: :desc)
    # else
    #   if @user.nil?
    #     @admission = Admission.where(:facility_id => @facilty.id, :isdischarged => true)
    #   else
    #     @admission = Admission.where(:facility_id => @facilty.id, :isdischarged => true, :user_id => @user.id)
    #   end
    # end
    # respond_to do |format|
    #   format.pdf {render :template => "ipd_patients/dischargelist_facility_print.pdf.erb", :pdf => "Dischargelist", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => {:spacing => 10,:html => {:template => 'layouts/pdf-header.html'}},:footer => {:html => { :template=>  'layouts/pdf-footer.html' },:spacing => 10, }, :margin => {:top=> @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom => 40 } }
    # end
  end

  # Add New Patient For Admission
  def new_patient
    @patient = Patient.new
    @patient.build_patient_history.initialize_nested_objects
    1.times { @patient.patientassets.build }
    respond_to do |format|
      format.js {}
    end
  end

  # Save Patient
  def register_patient
    # for calender purpose
    @admissiondate = params[:admissiondate] if params[:admissiondate].to_s != ''
    @admissiontime = Time.zone.parse(params[:admissiontime]).strftime('%I:%M %p') if params[:admissiontime].to_s != ''
    params[:patient][:reg_hosp_ids] = [current_user.organisation_id.to_s]
    params[:patient][:fullname] = (params[:patient][:salutation] + ' ' + params[:patient][:firstname] + ' ' + params[:patient][:lastname]).to_s.strip
    @patient = Patient.new(register_patient_create_params)
    if @patient.save!
      PatientIdentifier.create(patient_id: @patient.id, organisation_id: current_user.organisation_id, patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
      if @patient.dob.present?
        patient_birthday = PatientBirthday.find_by(patient_id: @patient.id)
        if patient_birthday
          patient_birthday.update(dob: @patient.dob.strftime('%d%m'))
        else
          PatientBirthday.create(patient_id: @patient.id, dob: @patient.dob.strftime('%d%m'))
        end
      end
      # model method for exact_age
      @patient.get_exact_age(@patient.age.to_i, @patient.age_month.to_i)

      @admission = Admission.new
      @admission.patient = @patient
      @admission.user_id = current_user.id.to_s

      @facilities = Common.new.fetch_facilities(user: current_user)
      @departments = Common.new.fetch_departments(facilities: @facilities)

      # doctor will make admision only for his patient.
      if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
        @users = []
        @users << current_user
      else
        @users = Common.new.fetch_users(org_type: current_user.organisation.type, organisation_id: current_user.organisation.id, facility_id: current_facility.id, department_id: @departments.first.id)
      end
    end

    # Reference Doc
    if (params[:ref_doc_name] != '') && !ReferringDoctor.where(name: params[:ref_doc_name], hospital_name: params[:ref_doc_place], user_id: current_user.id).exists?
      @referring_doc = ReferringDoctor.new
      @referring_doc[:name] = params[:ref_doc_name]
      @referring_doc[:hospital_name] = params[:ref_doc_place]
      @referring_doc[:speciality] = params[:ref_doc_speciality]
      @referring_doc[:mobile_number] = params[:ref_doc_number]
      @referring_doc[:email] = params[:ref_doc_email]
      @referring_doc[:city] = params[:ref_doc_city]
      @referring_doc[:user_id] = current_user.id
      @referring_doc.save
      @patient.update_attributes(referring_doctor_id: @referring_doc.id)
    else
      # @patient.update_attributes(referring_doctor_id: params[:patient_admission][:reference]['0'][:ref_doc_id])
    end

    # PatientRegSource
    @source_type = params[:patient_admission][:reference]['0'][:source]
    if (params[:patient_admission][:reference]['0'][:source_detail] != '') && (params[:patient_admission][:reference]['0'][:source] == 'family')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient_admission][:reference]['0'][:source_detail]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!

    elsif (params[:patient_admission][:reference]['0'][:source_detail] != '') && (params[:patient_admission][:reference]['0'][:source] == 'referingdoc')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient_admission][:reference]['0'][:source_detail]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!

    elsif (params[:patient_admission][:reference]['0'][:source_detail] != '') && (params[:patient_admission][:reference]['0'][:source] == 'internet')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient_admission][:reference]['0'][:source_detail]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!

    elsif (params[:patient_admission][:reference]['0'][:source_info] != '') && (params[:patient_admission][:reference]['0'][:source] == 'newspaper')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient_admission][:reference]['0'][:source_detail]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!

    elsif (params[:patient_admission][:reference]['0'][:source_detail] != '') && (params[:patient_admission][:reference]['0'][:source] == 'camp')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient_admission][:reference]['0'][:source_detail]
      @patient_source[:source_date] = params[:patient_admission][:reference]['0'][:source_date]
      @patient_source[:source_doctor] = params[:patient_admission][:reference]['0'][:source_doctor]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!

    elsif (params[:patient_admission][:reference]['0'][:source_detail] != '') && (params[:patient_admission][:reference]['0'][:source] == 'other')

      @patient_source = PatientRegistrationSource.new
      @patient_source[:source_type] = @source_type
      @patient_source[:source_info] = params[:patient_admission][:reference]['0'][:source_detail]
      @patient_source[:patient_id] = @patient.id
      @patient_source.save!
    end

    @wards = Ward.where(facility_id: current_facility.id)
    respond_to do |format|
      format.js { render 'admit_patient', layout: false }
    end
  end

  def admit_patient
    # for calender purpose
    @admissiondate = params[:admissiondate] if params[:admissiondate].to_s != ''
    @admissiontime = Time.zone.parse(params[:admissiontime]).strftime('%I:%M %p') if params[:admissiontime].to_s != ''
    @patient = Patient.find_by(id: params[:patientid])
    @admission = Admission.new
    @admission.patient = @patient
    @admission.user_id = current_user.id.to_s

    @facilities = Common.new.fetch_facilities(user: current_user)
    @departments = Common.new.fetch_departments(facilities: @facilities)

    @wards = Ward.where(facility_id: current_facility.id)
    # doctor will make admision only for his patient.
    if current_user.roles[0].try(:name) == 'doctor' || current_user.roles[1].try(:name) == 'doctor'
      @users = []
      @users << current_user
    else
      @users = Common.new.fetch_users(org_type: current_user.organisation.type, organisation_id: current_user.organisation.id, facility_id: current_facility.id, department_id: @departments.first.id)
    end
    @admission.user_id = @users.first.id
    respond_to do |format|
      format.js { render 'admit_patient', layout: false }
    end
  end

  # Select Bed Room For Admitted Patient
  def selected_bed_room
    id = params[:ajax][:id]
    @label = params[:ajax][:label]
    patient_ward_bed_room_array = id.split('XXXXX')
    @patient = Patient.find_by(id: patient_ward_bed_room_array[0])
    @ward = Ward.find_by(id: patient_ward_bed_room_array[1])
    @room = Room.find_by(id: patient_ward_bed_room_array[2])
    @bed = @room.beds.find_by(id: patient_ward_bed_room_array[3])
    respond_to do |format|
      format.js { render 'ipd_patients/js/selected_bed_room', layout: false }
    end
  end

  # Create New Admission
  def admission_done
    params[:admission][:display_id] = CommonHelper.get_ipd_record_identifier(current_user)
    @admission = Admission.new(admission_create_params)
    if @admission.save
      # Change bed Status
      Room.find(@admission.room_id).beds.find(@admission.bed_id).update(status: 1669000) if @admission.bed_id
      # Logic for correct admissiontime
      @meridian = params[:admission][:admissiontime].split(' ')[1].to_s
      @hour = params[:admission][:admissiontime].split(':')[0]
      @hours = if @meridian == 'AM'
                 if @hour.to_s == '12'
                   0o0
                 else
                   @hour
                 end
               else
                 if @hour.to_s == '12'
                   @hour
                 else
                   @hour.to_i + 12
                 end
               end
      @minutes = params[:admission][:admissiontime].split(':')[1].to_i
      @date = params[:admission][:admissiondate].split('/')[0]
      @month = params[:admission][:admissiondate].split('/')[1]
      @year = params[:admission][:admissiondate].split('/')[2]
      @followup_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)
      @admission.update(admissiontime: @followup_date_time)
      # Logic Ends

      admission_count = Admission.where(admissiondate: @admission.admissiondate, user_id: @admission.user_id, facility_id: @admission.facility_id).count
      patient_admission = DailyReport.find_by(date: Date.current, facility_id: @admission.facility_id.to_s, specialty_id: @admission.specialty_id)
      ipd_patient_ids = Admission.where(user_id: current_user.id, admissiondate: Date.current, facility_id: @admission.facility_id).pluck(:patient_id)
      ipd_new_patient_count = 0
      ipd_old_patient_count = 0
      ipd_patient_ids.each do |pat_id|
        pat = Patient.find_by(id: pat_id)
        if pat.created_at.to_date == Date.current
          ipd_new_patient_count += 1
        else
          ipd_old_patient_count += 1
        end
      end
      if patient_admission.nil?
        @patient_admission = DailyReport.new
        @patient_admission.user_id = @admission.doctor
        @patient_admission.date = @admission.admissiondate
        @patient_admission.admission_count = admission_count
        @patient_admission.month = @admission.admissiondate.month
        @patient_admission.year = @admission.admissiondate.year
        @patient_admission.organisation_id = @admission.user.organisation_id.to_s
        @patient_admission.facility_id = @admission.facility_id.to_s
        @patient_admission.specialty_id = @admission.specialty_id.to_s
        @patient_admission.save!
      else
        patient_admission.update_attributes(admission_count: admission_count, facility_id: @admission.facility_id.to_s, ipd_new_patient_count: ipd_new_patient_count, ipd_old_patient_count: ipd_old_patient_count)
      end
      # code for PatientOtherIdentifier
      @mr_no = params[:mr_no]
      @ip_no = params[:ip_no]
      unless @mr_no == '' && @ip_no == ''
        patient_other_identifier = PatientOtherIdentifier.new
        patient_other_identifier.mr_no = @mr_no
        patient_other_identifier.ip_no = @ip_no
        patient_other_identifier.patient_id = @admission.patient_id
        patient_other_identifier.organisation_id = current_user.organisation.id
        patient_other_identifier.facility_id = @admission.facility_id.to_s
        patient_other_identifier.doctor = @admission.doctor
        patient_other_identifier.save
      end

      @admission_all = if current_user.role_ids[0] == 106292003 || current_user.role_ids[0] == 159561009
                         Admission.where(facility_id: current_facility.id.to_s, is_deleted: false)
                       else
                         Admission.where(facility_id: current_facility.id.to_s, doctor: current_user.id.to_s, is_deleted: false)
                       end
      @current_date = @admission.admissiondate

      # For Provisional OT
      if params[:otschedule]
        params[:otschedule].to_unsafe_h.each.with_index do |ot, _i|
          if ot[1][:decider] == 'Link'
            OtSchedule.find_by(id: ot[1][:id]).update_attributes(admission_id: @admission.id)
          elsif ot[1][:decider] == 'Delete'
            OtSchedule.find_by(id: ot[1][:id]).update_attributes(is_deleted: true, admission_id: @admission.id)
          end
        end
      end
      # OtSchedule.where(patient_id: @admission.patient_id).each do |otschedule|
      #   otschedule.update_attributes(admission_id: @admission.id.to_s)
      # end
      @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)

      find_admission_list_views

      respond_to do |format|
        format.js { render 'admission_done' }
      end

      Patients::Summary::TimelineWorker.call(event_name: 'IPD_ADMISSION', sub_event_name: 'SCHEDULED', admission_id: @admission.id, user_id: current_user.id, user_name: current_user.fullname)
    end
  end

  # TPA Form
  def tpa_insurance
    @admission = Admission.find_by(id: params[:admission_id])
    @patient = Patient.find_by(id: params[:patient_id])
    @tpa = Tpa.find_by(id: params[:tpa_id])

    respond_to do |format|
      format.js { render 'ipd/tpa/edit', layout: false }
    end
  end

  def save_tpa_insurance
    @tpa = Tpa.find_by(id: params[:id])
    if @tpa.update_attributes(tpa_params)
      if @tpa.is_insured == true
        respond_to do |format|
          format.js { render 'ipd/tpa/show', layout: false }
        end
      else
        respond_to do |format|
          format.js { render 'ipd/tpa/close', layout: false }
        end
      end
    end
  end

  # Assign Bed or Change Bed for Existing Patients
  def new_bed
    @admission = Admission.find_by(id: params[:admissionid])
    # @patient = Patient.find_by(:id => params[:patientid])
    respond_to do |format|
      format.js { render 'new_bed', layout: false }
    end
  end

  # Update/Save Bed Changes
  def add_bed
    @admission = Admission.find_by(id: params[:admission_id])
    # Change Existing Bed Status to Unoccupied
    unless @admission.room_id.nil?
      Room.find(@admission.room_id).beds.find(@admission.bed_id).update_attributes(status: 78848005)
    end
    if @admission.update_attributes(admission_create_params)
      Room.find(@admission.room_id).beds.find(@admission.bed_id).update_attributes(status: 1669000)
      @admission_selected = @admission
      @tpa = @admission

      # Assigning Bed in file -- /inpatient/ipd_record/admission_note/ophthalmology_notes/_admission_details.html.erb:38
      ward, room, bed = @admission.set_bed_details
      @bed_details = "#{bed&.code}(#{ward&.name}/#{room&.name})"

      respond_to do |format|
        format.js { render 'ipd_patients/js/add_bed' }
      end
    else
      respond_to do |format|
        format.js { render 'ipd_patients/js/add_bed' }
      end
    end
  end

  # Get Bed Dropdown
  def get_bed_count
    @room = Room.find_by(id: params[:room_id]).beds.where(status: 78848005).pluck('code', 'id', 'price')
    render json: @room.to_json
  end

  # New Patient Registration
  def registration
    if !params.key?(:patientid)
      @patient = Patient.new(admission_patient_create_params)
      if @patient.save!
        if @patient.dob.present?
          patient_birthday = PatientBirthday.find_by(patient_id: @patient.id)
          if patient_birthday
            patient_birthday.update(dob: @patient.dob.strftime('%d%m'))
          else
            PatientBirthday.create(patient_id: @patient.id, dob: @patient.dob.strftime('%d%m'))
          end
        end
        if params[:patientphoto]
          patientasset = Patientasset.new
          patientasset.patient = @patient
          patientasset.extension = MIME::Types[paper_report_params[:reportfile].content_type.to_s].first.sub_type
          patientasset.assetpath.create_directory(patientasset.assetpath.set_store_dir('patients', 'photos'))
          patientasset.patientassetid = _patientassetid
          patientasset.assetpath = paper_report_params[:reportfile]
          patientasset.contenttype = paper_report_params[:reportfile].content_type
          patientasset.assettype = MIME::Types[paper_report_params[:reportfile].content_type.to_s].first.media_type
          patientasset.assetextension = MIME::Types[paper_report_params[:reportfile].content_type.to_s].first.sub_type
          patientasset.reporteddate = paper_report_params[:reporteddate]
          patientasset.reportedtime = paper_report_params[:reportedtime]
          patientasset.patient_id = @patient.id
          patientasset.assetpath.store!(paper_report_params[:reportfile])
        end
      end
    else
      @patient = Patient.find(params[:patientid])
    end
    @admission = Admission.new
    @admission.patient = @patient

    @facilities = Common.new.fetch_facilities(user: current_user)
    @departments = Common.new.fetch_departments(facilities: @facilities)
    @users = Common.new.fetch_users(org_type: current_user.organisation.type, organisation_id: current_user.organisation.id, facility_id: current_facility.id, department_id: @departments.first.id)

    respond_to do |format|
      format.js { render 'newpatientregistration' }
    end
  end

  # Save Admission
  def admission
    params[:admission][:display_id] = CommonHelper.get_ipd_record_identifier(current_user)
    @admission = Admission.new(admission_create_params)
    if @admission.save
      respond_to do |format|
        format.js { render 'admissionlist' }
      end
    end
  end

  # Add OT From OT Tab
  def addot
    @otschedule = OtSchedule.new
    @facilities = Common.new.fetch_facilities(user: current_user)
    @departments = Common.new.fetch_departments(facilities: @facilities)
    @users = Common.new.fetch_users(org_type: current_user.organisation.type, organisation_id: current_user.organisation.id, facility_id: current_facility.id, department_id: @departments.first.id)
    @otschedule.user_id = @users.first.id

    @otdate = if params[:ottime] == 'current_time'
                Date.current.strftime('%d/%m/%Y')
              else
                params[:otdate]
              end
    if params[:ottime] == 'current_time'
      @ottime = Time.zone.parse('8:00 AM').strftime('%I:%M %p')
      @otendtime = ''
    else
      @ottime = params[:ottime]
      @otendtime = params[:otendtime]
    end

    respond_to do |format|
      format.js { render 'ipd_patients/js/addot' }
    end
  end

  # Add OT From Patient Listing Datatable for Admission
  def scheduleot
    @source = if params[:from] == 'counsellor'
                'counsellor'
              else
                'other'
              end
    @appointment = params[:appointment_id]
    @patient = Patient.find_by(id: params[:patient_id])
    if params[:admission_id]
      @admission = Admission.find_by(id: params[:admission_id])
    elsif params[:appointment_id]
      @admission_present = Admission.find_by(patient_id: @patient.id.to_s, is_deleted: false, isdischarged: false)
      @admission = @admission_present unless @admission_present.nil?
    end
    @otschedule = OtSchedule.new

    if params[:ottime] == 'current_time'
      @ottime = Time.zone.parse('8:00 AM').strftime('%I:%M %p')
      @otendtime = ''
    else
      @ottime = params[:ottime]
      @otendtime = params[:otendtime]
    end

    @facilities = Common.new.fetch_facilities(user: current_user)
    @departments = Common.new.fetch_departments(facilities: @facilities)
    @users = Common.new.fetch_users(org_type: current_user.organisation.type, organisation_id: current_user.organisation.id, facility_id: current_facility.id, department_id: @departments.first.id)
    @otschedule.user_id = @users.first.id
    set_procedure_diagnosis_data_for_ot_schedule
    respond_to do |format|
      format.js { render 'ipd_patients/js/scheduleot' }
    end
  end

  # Save OT
  def makeot
    @appointment = params[:ot_schedule][:appointment_id]
    if params[:ot_schedule][:from] == 'counsellor'
      @counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: params[:ot_schedule][:appointment_id])
      surgery_dates = @counsellor_workflow.surgerydates << params[:ot_schedule][:otdate]
      @counsellor_workflow.update(surgerydates: surgery_dates)
      @counsellor_workflow.converted
      converted_state_array = @counsellor_workflow.converted_state
      converted_state_array << 'Surgery'
      @counsellor_workflow.update(converted_state: converted_state_array)
    end
    params[:ot_schedule][:display_id] = CommonHelper.get_ipd_record_identifier(current_user)
    @otschedule = OtSchedule.new(otschedule_create_params)
    if @otschedule.save
      @active_tab = if @otschedule.admission_id
                      if @otschedule.admission.patient_arrived
                        'Admitted'
                      else
                        'Scheduled'
                      end
                    else
                      'Scheduled'
                    end
      @hour = params[:ot_schedule][:ottime].split(':')[0]
      @hours = if params[:ot_schedule][:ottime].split(' ')[1] == 'AM'
                 if @hour.to_s == '12'
                   0o0
                 else
                   @hour.to_i
                 end
               else
                 if @hour.to_s == '12'
                   @hour.to_i
                 else
                   @hour.to_i + 12
                 end
               end
      @minutes = params[:ot_schedule][:ottime].split(':')[1].to_i
      @date = params[:ot_schedule][:otdate].split('/')[0]
      @month = params[:ot_schedule][:otdate].split('/')[1]
      @year = params[:ot_schedule][:otdate].split('/')[2]
      @ottime = Time.new(@year, @month, @date, @hours, @minutes, 0)
      @otschedule.update(ottime: @ottime, otendtime: (@ottime + 30.minutes))

      if @otschedule.ottime > @otschedule.otendtime
        @otschedule.update_attributes(otendtime: (@otschedule.ottime + 30.minutes))
      end
      ot_count = OtSchedule.where(otdate: @otschedule.otdate, user_id: @otschedule.user_id).count
      patient_ot = DailyReport.find_by(date: Date.current, facility_id: @otschedule.facility_id.to_s, specialty_id: @otschedule.specialty_id)
      if patient_ot.nil?
        @ot_patient_report = DailyReport.new
        @ot_patient_report.user_id = @otschedule.surgeonname.to_s
        @ot_patient_report.date = @otschedule.otdate
        @ot_patient_report.ot_count = ot_count
        @ot_patient_report.month = @otschedule.otdate.month
        @ot_patient_report.year = @otschedule.otdate.year
        @ot_patient_report.organisation_id = @otschedule.user.organisation_id.to_s
        @ot_patient_report.facility_id = @otschedule.facility_id.to_s
        @ot_patient_report.specialty_id = @otschedule.specialty_id.to_s
        @ot_patient_report.save!
      else
        patient_ot.update_attributes(ot_count: ot_count)
      end
      if params[:procedure]
        if params[:procedure].count > 0
          params[:procedure].each_value do |proc|
            procedure = Inpatient::Procedure.find_by(id: proc['id'])
            procedure.update(iol: proc['iol'], iol_updated_at: Time.current, ot_schedule_id: @otschedule.id, procedurestatus: proc['status'], procedureside: proc['side'], surgerydate: proc['surgerydate'])
          end
        end
      end

      # For RHS VIEW (Appt)
      @patient = Patient.find_by(id: @otschedule.patient_id)
      @ot_schedules = OtSchedule.where(patient_id: @otschedule.patient_id.to_s, is_deleted: false, admission_id: nil)

      respond_to do |format|
        format.js { render 'ipd_patients/js/makeot' }
      end

      Patients::Summary::TimelineWorker.call(event_name: 'IPD_OT', sub_event_name: 'SCHEDULED', ot_id: @otschedule.id, user_id: current_user.id, user_name: current_user.fullname)
    else
      respond_to do |format|
        format.js { render 'ipd_patients/js/makeot' }
      end
    end
  end

  # Edit OT
  def editot
    @source = if params[:from] == 'counsellor'
                'counsellor'
              else
                'other'
              end
    @appointment = params[:appointment_id]
    @facilities = current_user.facilities
    @patient = Patient.find_by(id: params[:patient_id])
    @otschedule = OtSchedule.find_by(id: params[:otschedule_id])
    @admission = Admission.find_by(id: @otschedule.admission_id)
    set_procedure_diagnosis_data_for_ot_schedule
    respond_to do |format|
      format.js { render 'ipd_patients/js/editot' }
    end
  end

  # Update OT
  def rescheduleot
    @appointment_id = params[:ot_schedule][:appointment_id]
    if params[:ot_schedule][:from] == 'counsellor'
      @counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: @appointment_id)
      surgery_dates = @counsellor_workflow.surgerydates << params[:ot_schedule][:otdate]
      @counsellor_workflow.update(surgerydates: surgery_dates)
      @counsellor_workflow.converted
      converted_state_array = @counsellor_workflow.converted_state
      converted_state_array << 'Surgery'
      @counsellor_workflow.update(converted_state: converted_state_array)
    end
    params[:ot_schedule][:display_id] = CommonHelper.get_ipd_record_identifier(current_user)
    @otschedule = OtSchedule.find_by(id: params[:ot_schedule][:otschedule_id])
    if @otschedule.update_attributes(otschedule_create_params)

      @hour = params[:ot_schedule][:ottime].split(':')[0]
      @hours = if params[:ot_schedule][:ottime].split(' ')[1] == 'AM'
                 if @hour.to_s == '12'
                   0o0
                 else
                   @hour.to_i
                 end
               else
                 if @hour.to_s == '12'
                   @hour.to_i
                 else
                   @hour.to_i + 12
                 end
               end
      @minutes = params[:ot_schedule][:ottime].split(':')[1].to_i
      @date = params[:ot_schedule][:otdate].split('/')[0]
      @month = params[:ot_schedule][:otdate].split('/')[1]
      @year = params[:ot_schedule][:otdate].split('/')[2]
      @ottime = Time.new(@year, @month, @date, @hours, @minutes, 0)
      @otschedule.update(ottime: @ottime, otendtime: (@ottime + 30.minutes))

      if @otschedule.ottime > @otschedule.otendtime
        @otschedule.update_attributes(otendtime: (@otschedule.ottime + 30.minutes))
      end
    end
    if params[:procedure]
      if params[:procedure].count > 0
        params[:procedure].each_value do |proc|
          procedure = Inpatient::Procedure.find_by(id: proc['id'])
          procedure.update(iol: proc['iol'], iol_updated_at: Time.current, ot_schedule_id: @otschedule.id, procedurestatus: proc['status'], procedureside: proc['side'], surgerydate: proc['surgerydate'])
        end
      end
    end
    respond_to do |format|
      format.js { render 'ipd_patients/js/rescheduleot' }
    end
    Patients::Summary::TimelineWorker.call(event_name: 'IPD_OT', sub_event_name: 'RESCHEDULED', ot_id: @otschedule.id, user_id: current_user.id, user_name: current_user.fullname)
  end

  def deleteot
    @ot = OtSchedule.find_by(id: params[:id])
    @case_sheet = CaseSheet.find_by(id: @ot.case_sheet_id)
    @active_ot = if params[:id] == params[:active_id]
                   @ot
                 else
                   OtSchedule.find_by(id: params[:active_id])
                 end
    @admission_list_view = AdmissionListView.find_by(admission_id: @ot.admission_id)
    @ot.update(is_deleted: true)
    @existing_admission = Admission.find_by(patient_id: @ot.patient_id, isdischarged: false, is_deleted: false)

    # For RHS VIEW (Appt)
    @patient = Patient.find_by(id: @ot.patient_id)
    @ot_schedules = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false).sort(ottime: :asc)

    find_admission_list_views

    respond_to do |format|
      format.js {}
    end
    Patients::Summary::TimelineWorker.call(event_name: 'IPD_OT', sub_event_name: 'CANCELLED', ot_id: @ot.id, user_id: current_user.id, user_name: current_user.fullname)
  end

  def engageot
    @ot = OtSchedule.find_by(id: params[:ot_id])
    admission = Admission.find_by(id: @ot.admission_id)
    @ot_status = @ot.is_engaged
    if @ot_status
      @ot.update_attributes(is_engaged: false)
      admission.admission_milestones.where(:position.in => [6, 7], ot_id: @ot.id.to_s).destroy_all
      admission.update_attributes(admission_stage: 'pre_operative')

      pst = PatientSummaryTimeline.find_by(event_name: 'IPD OT', sub_event_name: 'ENGAGED', query: { _id: @ot.id.to_s })
      pst&.delete
    else
      @ot.update_attributes(is_engaged: true)
      admission.update_attributes(admission_stage: 'intra_operative')
      user_id = current_user.id

      existing_milestone = admission.admission_milestones.find_by('$or' => [{ :position.in => [6, 7], ot_id: @ot.id },
                                                                            { :position.in => [9, 10] }])

      AdmissionsHelper.update_milestone(admission, 'ot_engaged', 6, user_id, @ot.id) unless existing_milestone.present?

      Patients::Summary::TimelineWorker.call(event_name: 'IPD_OT', sub_event_name: 'ENGAGED', ot_id: @ot.id, user_id: user_id, user_name: current_user.fullname)
    end
    render json: { "status": @ot.is_engaged }
  end

  def completeot
    @ot = OtSchedule.find_by(id: params[:ot_id])
    @admission = Admission.find_by(id: @ot.admission_id)
    operative_notes = Inpatient::IpdRecord.find_by(admission_id: @ot.admission_id)&.operative_notes.to_a
    if @admission&.isdischarged
      render json: { "status": 'Discharged' }
    else
      if @ot.operation_done
        @ot.update_attributes(operation_done: false, is_engaged: true)
        @admission.admission_milestones.where(:position.in => [7, 9, 10], ot_id: @ot.id.to_s).destroy_all
        @admission.update_attributes(admission_stage: 'intra_operative')

        pst = PatientSummaryTimeline.find_by(event_name: 'IPD OT', sub_event_name: 'COMPLETED', query: { _id: @ot.id.to_s })
        pst&.delete
      else
        @ot.update_attributes(operation_done: true, is_engaged: false)

        existing_milestone = @admission.admission_milestones.find_by('$or' => [{ position: 7, ot_id: @ot.id },
                                                                               { :position.in => [9, 10] }])
        unless existing_milestone.present?
          AdmissionsHelper.update_milestone(@admission, 'ot_completed', 7, current_user.id, @ot.id)
        end

        @admission.update_attributes(admission_stage: 'post_operative') if operative_notes.count > 0

        if @admission.dischargedate
          if @ot.otdate > @admission.dischargedate
            @admission.update_attributes(dischargedate: Date.current, dischargetime: Time.current)
          end
        end
        Patients::Summary::TimelineWorker.call(event_name: 'IPD_OT', sub_event_name: 'COMPLETED', ot_id: @ot.id, user_id: current_user.id, user_name: current_user.fullname)
      end

      render json: { "status": @ot.operation_done }
    end
  end

  def calendar_ot_details
    @ot = OtSchedule.find_by(id: params[:ot_id])

    @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, version: 'v21.0')
    @cash_register_templates = CashRegisterTemplate.where(user_id: current_user.id)

    respond_to do |format|
      # format.html { render partial: "opd_appointments/calendar/calendar_appointment_details.html", layout: false }
      format.html { render partial: 'inpatient/home/ot_management/calendar_ot_details.html', layout: false }
    end
  end

  def admission_details
    @admission_selected = Admission.find_by(id: params[:admission_id])
    @current_date = params[:current_date]
    @doctor = params[:doctor]

    respond_to do |format|
      format.html { render partial: 'inpatient/home/admission_management/admission_details.html', layout: false }
    end
  end

  def ward_details
    @current_date = params[:current_date]
    @doctor = params[:doctor]
    @room = Room.find(params[:room_id])
    # if @doctor == "All" || @doctor.nil?
    #   # Need Facility Changes
    #   @admission = Admission.where(facility_id: current_user.facility_ids[0])
    # else
    #   @admission = Admission.where(facility_id: current_user.facility_ids[0], doctor: @doctor)
    # end

    respond_to do |format|
      format.html { render partial: 'inpatient/home/ward_management/ward_details.html', layout: false }
    end
  end

  def ward_patient_details
    @admission = Admission.find_by(id: params[:admission_id])

    respond_to do |format|
      # format.html { render partial: "opd_appointments/calendar/calendar_appointment_details.html", layout: false }
      format.html { render partial: 'inpatient/home/ward_management/ward_patient_details.html', layout: false }
    end
  end

  def sidebar_details
    @current_date = Date.parse(params[:current_date])
    if params[:doctor] == 'all' || params[:doctor].nil?
      @admission_all = Admission.where(facility_id: current_facility.id.to_s, is_deleted: false)
      @doctor = 'all'
    else
      @admission_all = Admission.where(facility_id: current_facility.id.to_s, doctor: params[:doctor], is_deleted: false)
      @doctor = params[:doctor]
    end
    @patient = params[:patient]
    respond_to do |format|
      # format.html { render partial: "opd_appointments/calendar/calendar_appointment_details.html", layout: false }
      format.html { render partial: 'inpatient/home/admission_management/sidebar_summary.html', layout: false }
    end
  end

  def room_map(rooms)
    map ||= []
    c = 0
    s = ''
    rooms.each do |_room|
      c += 1
      if c % 5 == 0
        map << s
        s = ''
      end
      s += 'e'
    end
    map << s
    map
  end

  def bed_map(beds)
    map ||= []
    c = 0
    s = ''
    beds.each do |_room|
      c += 1
      if c % 5 == 0
        map << s
        s = ''
      end
      s += 'e'
    end
    map << s
    map
  end

  def room_update
    @rooms = Ward.where('id = ?', params[:id])[0].rooms
    @room_m = room_map(@rooms)
    respond_to do |format|
      format.js
      format.json { render json: @room_m }
    end
  end

  def bed_update
    @beds = Room.where('id = ?', params[:id])[0].beds
    @bed_m = bed_map(@beds)
    respond_to do |format|
      format.js
      format.json { render json: @bed_m }
    end
  end

  def searchpatient
    # if params[:q].to_i != 0
    #   @patientlist = Patient.where(:mobilenumber => /#{Regexp.escape(params[:q])}/i,:reg_hosp_ids.in => [current_user.organisation_id.to_s])
    # else
    #   @patientlist = Patient.where(:fullname => /#{Regexp.escape(params[:q])}/i,:reg_hosp_ids.in => [current_user.organisation_id.to_s])
    # end
    # @patientlist = Patient.where(reg_hosp_ids: current_user.organisation_id.to_s, "$or" => [{mobilenumber: /#{Regexp.escape(params[:q])}/i}, {secondarymobilenumber: /#{Regexp.escape(params[:q])}/i}, {fullname: /#{Regexp.escape(params[:q])}/i}, {:id.in => PatientOtherIdentifier.where(mr_no: /#{Regexp.escape(params[:q])}/i).pluck(:patient_id)}]).uniq
    r_query = params[:q].split(' ').join('.*')
    @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, search: /#{r_query}/i).limit(10)
  end

  def searchpatientresultfocus
    @patient = Patient.find(params[:searchresultfocus][:patientid])
    @patient_ident = PatientOtherIdentifier.find_by(patient_id: params[:searchresultfocus][:patientid])
    respond_to do |format|
      format.js {}
    end
  end

  def searchpatientresultselect
    @patient = Patient.find(params[:searchresultselect][:patientid])
    @patient_ident = PatientOtherIdentifier.find_by(patient_id: params[:searchresultselect][:patientid])
    respond_to do |format|
      format.js {}
    end
  end

  def otcalendar; end

  def updatedischarge
    @patient = Patient.find_by_patientid(params[:admission][:patientid])
    @admission = Admission.find_by_admissionid(params[:admission][:admissionid])
    respond_to do |format|
      format.js { render 'updatedischarge', layout: false }
    end
  end

  # View all Notes For Patient
  def view_all_discharge_notes # not in use
    # @department = current_user.department.name.downcase
    @organisation = current_user.organisation
    @invoice = Invoice.find_by(admission_id: params[:admission_id])
    @invoice_all = Invoice.where(admission_id: params[:admission_id], patient_id: params[:patient_id], user_id: current_user.id).order(created_at: :desc)
    @patient = Patient.find_by(id: params[:patient_id])
    @patient_details = Hash[@patient.attributes.symbolize_keys]
    @admission = Admission.find_by(id: params[:admission_id])
    @tpa = @admission
    @ipdrecord = IpdRecord.find_by(id: params[:ipdrecord_id])
    @ipdrecord_admission = IpdRecord.find_by(admissionid: params[:admission_id], templatetype: 'admissionnote')
    @ipdrecord_operative = IpdRecord.find_by(admissionid: params[:admission_id], templatetype: 'operativenote')
    @ipdrecord_discharge = IpdRecord.find_by(admissionid: params[:admission_id], templatetype: 'dischargenote')
    respond_to do |format|
      format.js { render 'discharge_concept', layout: false }
    end
  end

  def discharge_print # not in use
    # @department = current_user.department.name.downcase
    @organisation = current_user.organisation
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @tpa = @admission
    @ipdrecord_admission = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id], template_type: 'admissionnote')
    @ipdrecord_operative = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id], template_type: 'operativenote')
    @ipdrecord_discharge = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id], template_type: 'dischargenote')
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'IPD')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'templates/ipd/common/discharge_print.pdf.erb', pdf: '', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { top: @print_settings['header_height'].to_f * 10, bottom: 40 } }
    end
  end

  def confirm_discharge
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @ipd_record = Inpatient::IpdRecord.find_by(admission_id: @admission.id.to_s)
  end

  def mark_for_discharge
    @admission = Admission.find_by(id: params[:admission_id])
    @patient = Patient.find_by(id: params[:patient_id])
    @ipd_record = Inpatient::IpdRecord.find_by(admission_id: @admission.id.to_s)

    find_admission_list_views

    if @admission.try(:created_from).to_s == 'Integration' # need to update for sankara medics
      # ApiIntegration::AdmissionStatusData.update(admission.id.to_s,'medics', admission.facility_id.to_s, 'markedForDischarge', admission.try(:dischargetime) || Time.now )
      @admission.update_attributes(marked_for_discharged: true)
      dischargetime = @admission.try(:dischargetime)
      dischargetime = Time.now if dischargetime.blank?
      ApiJobs::AdmissionStatusJob.perform_later(@admission.id.to_s, 'medics', @admission.facility_id.to_s,
                                                'markedForDischarge', dischargetime.strftime('%d/%m/%Y %R'))
    end
  end

  def discharge
    @admission = Admission.find_by(id: params[:admission_id])
    @patient = Patient.find_by(id: params[:patient_id])

    params[:admission][:dischargetime] = params[:admission][:dischargetime].split(' ')[0] + ' ' + params[:admission][:dischargetime].split(' ')[1] + ':59' + ' ' + params[:admission][:dischargetime].split(' ')[2] #there can be case where reports would be gejerate at same time as discharge, hence to show discharge first, we set time in sec to 59, so that discharge would come on top, we dont sort @patient_summary_timeline cause the patient can be readitted creating new records.
    
    if @admission
      admissiontime = @admission.admissiontime
      dischargetime = Time.zone.parse(params[:admission][:dischargetime])
      dischargedate = params[:admission][:dischargedate]

      dischargedate = @admission.admissiondate if admissiontime > dischargetime
      dischargetime = @admission.admissiontime if admissiontime > dischargetime

      @admission.update_attributes(isdischarged: true, dischargedate: dischargedate, dischargetime: dischargetime,
                                   admission_stage: 'post_discharge')

      AdmissionsHelper.update_milestone(@admission, 'patient_discharged', 10, current_user.id)

      @facilities = Common.new.fetch_facilities(user: current_user)
      @departments = Common.new.fetch_departments(facilities: @facilities)
      @admissionlist = Admission.where(isdischarged: false, facility_id: current_facility.id, department_id: @departments.first.id)
      discharge_count = Admission.where(isdischarged: true, dischargedate: Date.current, user_id: current_user.id).count
      @discharge_report = DailyReport.find_by(date: Date.current, facility_id: @admission.facility_id.to_s, specialty_id: @admission.specialty_id)
      @tpa_workflow = TpaInsuranceWorkflow.find_by(admission_id: @admission.id)
      @tpa_workflow.update(admission_status: 'discharged') if @tpa_workflow.present?
      # Correct Discharge TimeDate
      # @date = @admission.dischargedate.strftime("%d")
      # @month = @admission.dischargedate.strftime("%m")
      # @year = @admission.dischargedate.strftime("%Y")
      # @hours = @admission.dischargetime.strftime("%H")
      # @minutes = @admission.dischargetime.strftime("%M")
      # @discharge_time = Time.new(@year, @month, @date, @hours, @minutes, 0).in_time_zone(current_facility.time_zone)
      # @admission.update(dischargedate: @discharge_time, dischargetime: @discharge_time)

      admission_list_view = AdmissionListView.find_by(admission_id: @admission.id.to_s)
      if admission_list_view.user_id != current_user.id
        if ['receptionist', 'nurse', 'doctor', 'counsellor', 'tpa'].include?(current_user.primary_role)
          admission_list_view.send("assign_to_#{current_user.primary_role}", current_user.id, 'user', '')
        else
          admission_list_view.send('assign_to_doctor', @admission.doctor, 'user', '')
        end
      end
      admission_list_view.discharge(nil, 'discharge', '')

      if @discharge_report.nil?
        @new_discharge_report = DailyReport.new
        @new_discharge_report.user_id = @admission.user_id
        @new_discharge_report.date = @admission.dischargedate
        @new_discharge_report.discharge_count = discharge_count
        @new_discharge_report.month = @admission.dischargedate.month
        @new_discharge_report.year = @admission.dischargedate.year
        @new_discharge_report.organisation_id = @admission.organisation_id.to_s
        @new_discharge_report.facility_id = @admission.facility_id.to_s
        @new_discharge_report.specialty_id = @admission.specialty_id.to_s
        @new_discharge_report.save!
      else
        @discharge_report.update_attributes(discharge_count: discharge_count)
      end
      unless @admission.bed_id.nil?
        Room.find(@admission.room_id).beds.find(@admission.bed_id).update_attributes(status: 78848005)
      end

      case_sheet = CaseSheet.find_by(id: @admission.case_sheet_id)
      case_sheet.update(active_admission_id: nil) if case_sheet.present?

      if @admission.try(:created_from).to_s == 'Integration' # need to update for sankara medics
        LoggerService.new.integration(@admission.try(:dischargetime), 'integration', 'admission_discharge_time')

        dischargetime = @admission.try(:dischargetime)

        dischargetime = Time.now if dischargetime.blank?

        ApiJobs::AdmissionStatusJob.perform_later(@admission.id.to_s, 'medics', @admission.facility_id.to_s, 'discharged', dischargetime.strftime('%d/%m/%Y %R'))
      end

      find_admission_list_views

      # DischargeSmsJob.perform_later(@admission.id.to_s)
      SmsJob.perform_later('discharge_sms', @admission.id.to_s, @admission.class.to_s)
      CommunicationNotificationJob.perform_now('discharge_message', @admission.id.to_s, @admission.class.to_s)
      respond_to do |format|
        format.js { render 'discharge', layout: false }
      end
      Patients::Summary::TimelineWorker.call(event_name: 'IPD_ADMISSION', sub_event_name: 'DISCHARGED', admission_id: @admission.id, user_id: current_user.id, user_name: current_user.fullname)
      DischargeSmsJob.perform_later(@admission.id.to_s)
      object_config = {}
      object_config["class_name"] = "ipd_patients"
      object_config["method_name"] = "discharge"
      mandatory = {}
      mandatory["organisation_id"] = current_user["organisation_id"].to_s
      optional = {}
      others = {}
      mandatory["admission_id"] = @admission.id.to_s
      ProcessInBackgroundJob.set(queue: :urgent, wait_until: 0).perform_later(object_config, mandatory, optional, others)
    end
  end

  def discharge_from_ward
    @admission = Admission.find_by(id: params[:admission_id])
    @patient = Patient.find_by(id: params[:patient_id])
    if @admission
      @admission.update_attributes(isdischarged: true, dischargedate: Date.current, dischargetime: Time.current)
      @facilities = Common.new.fetch_facilities(user: current_user)
      @departments = Common.new.fetch_departments(facilities: @facilities)
      @admissionlist = Admission.where(isdischarged: false, facility_id: @facilities.first.id, department_id: @departments.first.id)
      discharge_count = Admission.where(isdischarged: true, dischargedate: Date.current, user_id: current_user.id).count
      @discharge_report = DailyReport.find_by(date: Date.current, facility_id: @admission.facility_id.to_s, specialty_id: @admission.specialty_id)
      if @discharge_report.nil?
        @new_discharge_report = DailyReport.new
        @new_discharge_report.user_id = @admission.user_id
        @new_discharge_report.date = @admission.dischargedate
        @new_discharge_report.discharge_count = discharge_count
        @new_discharge_report.month = @admission.dischargedate.month
        @new_discharge_report.year = @admission.dischargedate.year
        @new_discharge_report.organisation_id = @admission.organisation_id.to_s
        @new_discharge_report.facility_id = @admission.facility_id.to_s
        @new_discharge_report.specialty_id = @admission.specialty_id.to_s
        @new_discharge_report.save!
      else
        @discharge_report.update_attributes(discharge_count: discharge_count)
      end
      unless @admission.bed_id.nil?
        Room.find(@admission.room_id).beds.find(@admission.bed_id).update_attributes(status: 78848005)
      end
      @admission_selected = Admission.find_by(id: params[:admission_id])
      @tpa = @admission_selected
      # DischargeSmsJob.perform_later(@admission.id.to_s)
      SmsJob.perform_later('discharge_sms', @admission.id.to_s, @admission.class.to_s)
      respond_to do |format|
        format.js { render 'discharge_from_ward', layout: false }
      end
    end
  end

  def discharged
    @patient = Patient.find_by_patientid(params[:admission][:patientid])
    @admission = Admission.find_by_admissionid(params[:admission][:admissionid])
    if @admission
      @admission.update_attributes(isdischarged: 'Y')
      @admissionlist = Admission.where(isdischarged: 'N')
      respond_to do |format|
        format.js { render 'discharged', layout: false }
      end
    end
  end

  def consent
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    respond_to do |format|
      format.js { render 'admissionconsent', layout: false }
    end
  end

  def print_admissionconsent
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @organisation = current_user.organisation
    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'ipd_patients/print_admissionconsent', pdf: 'AdmissionConsent', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def ot_consent
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    respond_to do |format|
      format.js { render 'otconsent', layout: false }
    end
  end

  def print_otconsent
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @organisation = current_user.organisation
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'ipd_patients/print_otconsent', pdf: 'AdmissionConsent', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings['left_margin'].to_f * 10, right: @print_settings['right_margin'].to_f * 10, top: @print_settings['header_height'].to_f * 10, bottom: @print_settings['footer_height'].to_f * 10 } }
    end
  end

  # def print_otconsent
  #   @patient = Patient.find_by(:id => params[:patient_id])
  #   @admission = Admission.find_by(:id => params[:admission_id])
  #   @organisation = current_user.organisation
  #   respond_to do |format|
  #     format.pdf { render :template => "ipd_patients/print_otconsent", :pdf => "AdmissionConsent", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => {:spacing => 10,:html => {:template => 'layouts/pdf-header.html'}},:footer => {:html => { :template=>  'layouts/pdf-footer.html' },:spacing => 10, }, :margin => {:top=> @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom => 40 } }
  #   end
  # end

  def admissionnote
    @patient = Patient.find_by_patientid(params[:admission][:patientid])
    @admission = Admission.find_by_admissionid(params[:admission][:admissionid])
    @note = AdmissionNote.where(_id: params[:admission][:admissionid]).first_or_create
    respond_to do |format|
      format.js { render 'admissionnote', layout: false }
    end
  end

  def dischargenote
    @patient = Patient.find_by_patientid(params[:admission][:patientid])
    @admission = Admission.find_by_admissionid(params[:admission][:admissionid])
    @note = DischargeNote.where(_id: params[:admission][:admissionid]).first_or_create
    respond_to do |format|
      format.js { render 'dischargenote', layout: false }
    end
  end

  def admissionsummary
    @note = AdmissionNote.find(params[:admission][:admissionid])
    @admission = Admission.find(params[:admission][:admissionid])
    respond_to do |format|
      format.js { render 'admissionnote', layout: false }
      format.pdf do
        render pdf: 'file_name', save_to_file: Rails.root.join('tmp', "#{@note.id}.pdf"), layout: 'pdfgen'
      end
    end
  end

  def dischargesummary; end

  def operativenote
    @patient = Patient.find_by_patientid(params[:admission][:patientid])
    @admission = Admission.find_by_admissionid(params[:admission][:admissionid])
    @note = OtNote.where(_id: params[:admission][:admissionid]).first_or_create
    respond_to do |format|
      format.js { render 'operativenote', layout: false }
    end
  end

  def saveprocedurenote
    @procedurenote = ProcedureNote.new(save_procedurenote_params)
    if @procedurenote.save
      respond_to do |format|
        format.js { head :ok }
      end
    end
  end

  def searchprocedurenotes
    @procedurenotes = ProcedureNote.where(:name => /#{params[:ajax][:name]}/i, :organisation_id => current_user.organisation_id.to_s, is_active: true, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }])
    respond_to do |format|
      format.js { render 'templates/ipd/ipd_partials/searchprocedurenotes', layout: false }
    end
  end

  def wardnotes; end

  def printotlist
    @datepicker_date = Date.parse(params[:otdate].to_s, '%d-%b-%Y').strftime('%Y-%m-%d').to_s
    @organisation = current_user.organisation
    @facility = Facility.find_by(id: params[:facility_id])
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'ipd_patients/otlist_print', pdf: 'AdmissionList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings['left_margin'].to_f * 10, right: @print_settings['right_margin'].to_f * 10, top: @print_settings['header_height'].to_f * 10, bottom: @print_settings['footer_height'].to_f * 10 } }
    end
  end

  def printotlist_by_facility
    @organisation = current_user.organisation
    @facility = Facility.find_by(id: params[:facility_id])
    @user = User.find_by(id: params[:user_id])
    @otschedule = if [[158965000], [158965000, 6868009]].include? current_user.role_ids
                    OtSchedule.where(otdate: Date.current, facility_id: @facility.id, user_id: current_user.id)
                  else
                    if @user.nil?
                      OtSchedule.where(otdate: Date.current, facility_id: @facility.id)
                    else
                      OtSchedule.where(otdate: Date.current, facility_id: @facility.id, user_id: @user.id)
                    end
                  end
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'ipd_patients/otlist_print_dashboard', pdf: 'AdmissionList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def printoperationnote; end

  def printconsentform; end

  def ot_surgeonname
    @user = User.where(facility_ids: params[:facility_id], role_ids: 158965000).pluck('fullname', 'id')
    @admission = Admission.where(facility_id: params[:facility_id], isdischarged: false, is_deleted: false).pluck('patient_id', 'id')
    @admission.map do |ad|
      patient_name = Patient.find_by(id: ad[0]).fullname
      ad << patient_name
    end
    respond_to do |format|
      format.json { render json: { user: @user, admission: @admission } }
    end
  end

  def otcalendar_data
    options = { facility_id: params[:facility_id], is_deleted: false }
    if params[:doctor_id].nil? || params[:doctor_id] == ''
      options = options.merge(surgeonname: params[:user_id])
    elsif params[:doctor_id] == 'all'

    else
      options = options.merge(surgeonname: params[:doctor_id])
    end

    @ot_list = OtSchedule.where(options).between(otdate: Date.parse(params[:start])..Date.parse(params[:end])).sort(ottime: :desc)

    respond_to do |format|
      format.json {}
    end
  end

  def edit_otcalendar_event
    OtSchedule.find(params[:ot_id]).update_attributes(otdate: Date.parse(params['ot_new_start']), ottime: Time.zone.parse(params['ot_new_start']), otendtime: Time.zone.parse(params['ot_new_end']))

    respond_to do |format|
      format.json {}
    end
  end

  def current_doctor_admission
    @current_date = Date.parse(params[:current_date])
    @admission_all = if params[:doctor] != 'all'
                       # Facility Change
                       Admission.where(facility_id: current_facility.id.to_s, doctor: params[:doctor], is_deleted: false)
                     else
                       # Facility Change
                       Admission.where(facility_id: current_facility.id.to_s, is_deleted: false)
                     end

    respond_to do |format|
      format.js {}
    end
  end

  def assign_bed
    admission = Admission.find_by(id: params[:admission_id])
    room = Room.find_by(id: params[:room_id])
    if room.present?
      ward = room.ward
      bed = room.beds.find_by(id: params[:bed_id])

      if admission.update_attributes(bed_id: bed.id, room_id: room.id, ward_id: ward.id, daycare: false)
        ward.update(in_use: true)
        room.update(in_use: true)
        bed.update(in_use: true, status: 1669000)
      end
    end

    render json: { "room": room.id.to_s }
  end

  private

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

  # def register_patient_create_params
  #
  #   params.require(:patient).permit(:fullname,:firstname,:lastname, :gender,:dob, :age, :mobilenumber,:email, :blood_group,:address_1,:address_2,:city,:state,:pincode,:emergencycontactname, :emergencymobilenumber, :maritalstatus, :specialstatus, :occupation, :reg_hosp_ids => [], patientassets_attributes: [:asset_path],patient_history_attributes: [ :patient_id, :patientid, :templatetype, :templateid, patientpersonalhistory_attributes: [problems: [] ], patientallergyhistory_attributes: [:others, antimicrobialagents: [], antifungalagents: [], nsaids: [], antiviralagents: [], contact: [], food: [],eyedrops: [] ] ])
  # end
  def register_patient_create_params
    params.require(:patient).permit!
  end

  def admission_create_params
    params.require(:admission).permit(:patient_id, :display_id, :admissiondate, :admissiontime, :dischargedate, :dischargetime, :scheduled_date, :scheduled_time, :isdischarged, :user_id, :organisation_id, :facility_id, :ward_id, :room_id, :bed_id, :admission_type, :admissionreason, :daycare, :doctor, :managementplan, :insurance_status)
  end

  def otschedule_create_params
    params.require(:ot_schedule).permit(:patient_id, :admission_id, :display_id, :otdate, :ottime, :otendtime, :user_id, :facility_id, :ward_id, :bed_type_id, :bed_id, :surgeonname, :procedurename, :theatreno, :theatrename)
  end

  def save_procedurenote_params
    params.require(:ajax).permit(:name, :proceduretext)
  end

  def tpa_params
    params.require(:tpa).permit(:is_insured, :insurance_name, :tpa_name, :tpa_contact_no, :policy_no, :insurer, :company_name, :employee_id, :comment, :patient_id, :admission_id, :insurance_status, :bracket_amount, :document_passport, :document_aadharcard, :document_electioncard, :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form)
  end

  def set_procedure_diagnosis_data_for_ot_schedule
    if @admission
      @clinical_note = Inpatient::IpdRecord::ClinicalNote.find_by(patient_id: @patient.id.to_s, admission_id: @admission.id.to_s)
    end
    last_opdrecord = OpdRecord.where(patientid: @patient.id.to_s).order('created_at DESC')[0]
    current_opdrecord = OpdRecord.where(appointmentid: @appointment).order('created_at DESC')[0]
    if current_opdrecord
      if @admission.specialty_id == '309988001'
        @performed_remaining = current_opdrecord.procedure
        @procedures = []
        @diagnosis = current_opdrecord.diagnosislist
      else
        if current_opdrecord.templatetype == 'freeform'
          @performed_remaining = current_opdrecord.free_procedure
          @diagnosis = current_opdrecord.diagnosis
        else
          @performed_remaining = current_opdrecord.procedurecomments
          @diagnosis = current_opdrecord.diagnosislist
        end
      end
    elsif @clinical_note
      @procedures = Inpatient::Procedure.where(ipdrecord_id: @clinical_note.id, :procedurestatus.in => ['Performed']).order('created_at DESC')
      if @admission.specialty_id == '309988001'
        @performed_remaining = Inpatient::Procedure.where(ipdrecord_id: @clinical_note.id).order('created_at DESC')
        @diagnosis = Inpatient::Diagnosis.where(ipdrecord_id: @clinical_note.id).order('created_at DESC')
      else
        @performed_remaining = Inpatient::Procedure.where(ipdrecord_id: @clinical_note.id).order('created_at DESC')
        @diagnosis = @clinical_note.diagnosis
      end
    elsif last_opdrecord
      if @admission.specialty_id == '309988001'
        @performed_remaining = last_opdrecord.procedure
        @procedures = []
        @diagnosis = last_opdrecord.diagnosislist
      else
        if last_opdrecord.templatetype == 'freeform'
          @performed_remaining = last_opdrecord.free_procedure
          @diagnosis = last_opdrecord.diagnosis
        else
          @performed_remaining = last_opdrecord.procedurecomments
          @diagnosis = last_opdrecord.diagnosislist
        end
      end
      # @performed_remaining = last_opdrecord.procedure
      # @procedures= []
      # @diagnosis= last_opdrecord.diagnosislist
    else
      @performed_remaining = []
      @procedures = []
      @diagnosis = []
    end
  end

  def find_admission_list_views
    patient_id = @admission&.patient_id || @patient&.id

    @admission_list_views = AdmissionListView.where(
      patient_id: patient_id, :current_state.nin => ['Discharged', 'Deleted']
    )
  end
end
