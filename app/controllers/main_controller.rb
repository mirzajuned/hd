class MainController < ApplicationController
  before_action :authorize, :check_role
  before_action :authorize_onboard
  respond_to :js, :html, :json
  layout "loggedin"

  def dashboard
    @newtask = TaskList.new()
    @showtask = TaskList.where(organisation_id: current_user.organisation_id).order(:created_at => :desc)
    @facility = Facility.where(:organisation_id => current_user.organisation_id).first

    @total_list_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1)
    @maintotalinvoice_opd = @total_list_opd.pluck(:net_amount)
    @total_list_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1)
    @maintotalinvoice_ipd = @total_list_ipd.pluck(:net_amount)
    @total_list_insurance = Invoice::Insurance.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1)
    @maintotalinvoice_insurance = @total_list_insurance.pluck(:net_amount)
    @total_list_cash_opd = CashRegister.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1).not.where(appointment_id: nil)
    @maintotalinvoice_cash_opd = @total_list_cash_opd.pluck(:total)
    @total_list_cash_ipd = CashRegister.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1).not.where(admission_id: nil)
    @maintotalinvoice_cash_ipd = @total_list_cash_ipd.pluck(:total)
    @total_list_pharmacy = Invoice::Inventories::Department::PharmacyInvoice.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1)
    @maintotalinvoice_pharmacy = @total_list_pharmacy.pluck(:total)
    @total_list_optical = Invoice::Inventories::Department::OpticalInvoice.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1)
    @maintotalinvoice_optical = @total_list_optical.pluck(:total)

    @pharmacy = Inventory::Department.find_by(facility_id: current_facility.id.to_s, department_id: 284748001)
    @optical = Inventory::Department.find_by(facility_id: current_facility.id.to_s, department_id: 50121007)

    respond_to do |format|
      format.html {}
      # if params[:custom] == 'login'
      format.js {}
      # end
    end
  end

  def save_task_list
    @showtask = TaskList.where(organisation_id: current_user.organisation_id).order(:created_at => :desc)
    @newtask = TaskList.new(task_list_params)
    @newtask.organisation_id = current_user.organisation_id.to_s
    @newtask.user_id = current_user.id.to_s
    if @newtask.save
      respond_to do |format|
        format.js { render 'main/dashboard_content/task_list/refresh_task_list.js.erb', layout: false }
      end
    end
  end

  def save_task_is_complete
    @showtask = TaskList.where(organisation_id: current_user.organisation_id).order(:created_at => :desc)
    @task = TaskList.find(params[:task_id])
    if @task.update(is_complete: params[:is_complete])
      respond_to do |format|
        format.js { render 'main/dashboard_content/task_list/refresh_task_list.js.erb', layout: false }
      end
    end
  end

  def delete_task
    @showtask = TaskList.where(organisation_id: current_user.organisation_id).order(:created_at => :desc)
    @task = TaskList.find(params[:task_id])
    if @task
      @task.delete
    end
    respond_to do |format|
      format.js { render 'main/dashboard_content/task_list/refresh_task_list.js.erb', layout: false }
    end
  end

  def get_user_id_appointment_count
    # @facility = Facility.find_by(:id => params[:facility_id])
    # print "Starting opd appointment"
    @user = User.where(:facility_ids => params[:facility_id], :role_ids => 158965000).pluck("fullname", "id")
    render :json => @user.to_json
    # print "Ending opd appointment"
  end

  def get_opd_appointment_count
    @facility = Facility.find_by(:id => params[:facility_id])
    @user = User.find_by(:id => params[:user_id])
    @fac_date = Appointment.where(:appointmentdate => Date.current, :facility_id => @facility.id.to_s)
    @scheduled_patient_doctor = @fac_date.where(:arrived => false, :appointmentstatus => 416774000, :consultant_id => current_user.id).count
    @patient_arrived_doctor = @fac_date.where(:arrived => true, :seen => false, :engaged => false, :appointmentstatus => 416774000, :consultant_id => current_user.id).count
    @patient_seen_doctor = @fac_date.where(:seen => true, :appointmentstatus => 416774000, :consultant_id => current_user.id).count
    @cancelled_patient_doctor = @fac_date.where(:appointmentstatus => 89925002, :consultant_id => current_user.id).count
    if @user.nil?
      @scheduled_patient_nurse = @fac_date.where(:arrived => false, :appointmentstatus => 416774000).count
      @patient_arrived_nurse = @fac_date.where(:arrived => true, :seen => false, :engaged => false, :appointmentstatus => 416774000).count
      @patient_seen_nurse = @fac_date.where(:seen => true, :appointmentstatus => 416774000).count
      @cancelled_patient_nurse = @fac_date.where(:appointmentstatus => 89925002).count
    else
      @scheduled_patient_nurse = @fac_date.where(:arrived => false, :appointmentstatus => 416774000, :consultant_id => @user.id.to_s).count
      @patient_arrived_nurse = @fac_date.where(:arrived => true, :seen => false, :engaged => false, :appointmentstatus => 416774000, :consultant_id => @user.id.to_s).count
      @patient_seen_nurse = @fac_date.where(:seen => true, :appointmentstatus => 416774000, :consultant_id => @user.id.to_s).count
      @cancelled_patient_nurse = @fac_date.where(:appointmentstatus => 89925002, :consultant_id => @user.id.to_s).count
    end

    respond_to do |format|
      format.js { render "main/dashboard_content/opd_dashboard_counter/opd_counter", :layout => false }
    end
  end

  def get_user_id_admission_count
    # @facility = Facility.find_by(:id => params[:facility_id])
    @user = User.where(:facility_ids => params[:facility_id], :role_ids => 158965000).pluck("fullname", "id")
    render :json => @user.to_json
  end

  def get_ipd_admission_count
    @facility = Facility.find_by(:id => params[:facility_id])
    @user = User.find_by(:id => params[:user_id])
    @admission_today_doctor = Admission.where(:admissiondate => Date.current, :facility_id => @facility.id.to_s, :doctor => current_user.id).count
    @patients_ot_doctor = OtSchedule.where(:otdate => Date.current, :facility_id => @facility.id.to_s, :doctor => current_user.id).count
    @admitted_patient_doctor = Admission.where(:facility_id => @facility.id.to_s, :doctor => current_user.id, :isdischarged => false).count
    @discharged_today_doctor = Admission.where(:facility_id => @facility.id.to_s, :doctor => current_user.id, :isdischarged => true, :dischargedate => Date.current).count
    if @user.nil?
      @admission_today_nurse = Admission.where(:admissiondate => Date.current, :facility_id => @facility.id.to_s).count
      @patients_ot_nurse = OtSchedule.where(:otdate => Date.current, :facility_id => @facility.id.to_s).count
      @admitted_patient_nurse = Admission.where(:facility_id => @facility.id.to_s, :isdischarged => false).count
      @discharged_today_nurse = Admission.where(:facility_id => @facility.id.to_s, :isdischarged => true, :dischargedate => Date.current).count
    else
      @admission_today_nurse = Admission.where(:admissiondate => Date.current, :facility_id => @facility.id.to_s, :doctor => @user.id.to_s).count
      @patients_ot_nurse = OtSchedule.where(:otdate => Date.current, :facility_id => @facility.id.to_s, :doctor => @user.id.to_s).count
      @admitted_patient_nurse = Admission.where(:facility_id => @facility.id.to_s, :isdischarged => false, :doctor => @user.id.to_s).count
      @discharged_today_nurse = Admission.where(:facility_id => @facility.id.to_s, :isdischarged => true, :dischargedate => Date.current, :doctor => @user.id.to_s).count
    end

    respond_to do |format|
      format.js { render "main/dashboard_content/ipd_dashboard_counter/ipd_counter", :layout => false }
    end
  end

  def get_user_id_other_count
    # @facility = Facility.find_by(:id => params[:facility_id])
    @user = User.where(:facility_ids => params[:facility_id], :role_ids => 158965000).pluck("fullname", "id")
    render :json => @user.to_json
  end

  def get_other_data_count
    @facility = Facility.find_by(:id => params[:facility_id])
    @user = User.find_by(:id => params[:user_id])
    @patients_total_doctor_opd = Appointment.where(:facility_id => @facility.id.to_s, :consultant_id => current_user.id).count
    @patients_total_doctor_ipd = Admission.where(:facility_id => @facility.id.to_s, :user_id => current_user.id).count
    @patients_total_doctor_ot = OtSchedule.where(:facility_id => @facility.id.to_s, :user_id => current_user.id).count
    if @user.nil?
      @patients_total_nurse_opd = Appointment.where(:facility_id => @facility.id.to_s).count
      @patients_total_nurse_ipd = Admission.where(:facility_id => @facility.id).count
      @patients_total_nurse_ot = OtSchedule.where(:facility_id => @facility.id.to_s).count
    else
      @patients_total_nurse_opd = Appointment.where(:facility_id => @facility.id.to_s, :consultant_id => @user.id.to_s).count
      @patients_total_nurse_ipd = Admission.where(:facility_id => @facility.id, :doctor => @user.id.to_s).count
      @patients_total_nurse_ot = OtSchedule.where(:facility_id => @facility.id.to_s, :doctor => @user.id.to_s).count
    end
    respond_to do |format|
      format.js { render "main/dashboard_content/other_data_dashboard_counter/other_data_counter", :layout => false }
    end
  end

  # def get_user_id_appointment_list
  #   @user = User.where(:facility_ids => params[:facility_id], :role_ids => 158965000, is_active: true).pluck("fullname","id")
  #   render :json =>  @user.to_json
  # end

  # def get_appointment_list
  #   @facility = Facility.find_by(id: params[:facility_id])
  #   @user = User.find_by(id: params[:user_id])

  #   respond_to do |format|
  #     format.js {render "main/dashboard_content/appointment_list_dashboard/appointment_list", :layout => false}
  #   end
  # end

  # def get_user_id_admission_list
  #   if params[:facility_id] == "0"
  #     @user = User.where(:facility_ids.in => current_user.facility_ids, :role_ids => 158965000, is_active: true).pluck("fullname","id")
  #   else
  #     @user = User.where(:facility_ids.in => [params[:facility_id]], :role_ids.in => [158965000], is_active: true).pluck("fullname","id")
  #   end
  #   render :json =>  @user.to_json
  # end

  def get_facility_specialties
    facility = Facility.find_by(id: params[:facility_id])
    specialties = Specialty.where(:id.in => facility.specialty_ids & current_user.specialty_ids)

    render :json => specialties.to_json
  end

  def get_users_from_specialty
    facility = Facility.find_by(id: params[:facility_id])
    users = User.where(facility_ids: params[:facility_id], role_ids: 158965000, specialty_ids: params[:specialty_id], is_active: true).pluck("fullname", "id")
    appointment_types = AppointmentType.where(facility_id: params[:facility_id], specialty_ids: params[:specialty_id], is_active: true).pluck(:label, :id)
    sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: current_user.organisation_id, specialty_ids: params[:specialty_id], is_active: true).pluck(:label, :id)

    users.map do |u|
      u << UserState.find_by(facility_id: params[:facility_id], user_id: u[1]).active_state if facility.show_user_state
    end

    render :json => { users: users.to_json, appointment_types: appointment_types.to_json, sub_appointment_types: sub_appointment_types.to_json }
  end

  def get_admission_list
    if params[:facility_id] == "0"
      @facility = "all"
    else
      @facility = Facility.find_by(:id => params[:facility_id])
    end
    if params[:current_date].present?
      @current_date = Date.parse(params[:current_date])
    else
      @current_date = Date.current
    end

    @user = User.find_by(:id => params[:user_id])
    respond_to do |format|
      format.js { render "main/showdashboardcontent.js.erb", :layout => false }
    end
  end

  def get_user_id_discharge_list
    # @facility = Facility.find_by(:id => params[:facility_id])
    @user = User.where(:facility_ids => params[:facility_id], :role_ids => 158965000).pluck("fullname", "id")
    render :json => @user.to_json
  end

  def get_discharge_list
    @facility = Facility.find_by(:id => params[:facility_id])
    @user = User.find_by(:id => params[:user_id])
    respond_to do |format|
      format.js { render "main/dashboard_content/discharge_list_dashboard/discharge_list", :layout => false }
    end
  end

  def get_user_id_ot_list
    # @facility = Facility.find_by(:id => params[:facility_id])
    @user = User.where(:facility_ids => params[:facility_id], :role_ids => 158965000).pluck("fullname", "id")
    render :json => @user.to_json
  end

  def get_ot_list
    @facility = Facility.find_by(:id => params[:facility_id])
    @user = User.find_by(:id => params[:user_id])
    respond_to do |format|
      format.js { render "main/dashboard_content/ot_list_dashboard/ot_list", :layout => false }
    end
  end

  def email
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def patientdirectory
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def userdashboard
    @facilities = Common.new.fetch_facilities(:user => current_user)
    @departments = Common.new.fetch_departments(:facilities => @facilities)
    # current users facilities and departments are saved to user
    @users = Common.new.fetch_users(:org_type => current_user.organisation.type, :organisation_id => current_user.organisation.id, :facility_id => @facilities.first.id, :department_id => @departments.first.id)
    @current = current_user
  end

  def calendar_time_slot
    @is_discharge = params[:is_discharge].present? ? params[:is_discharge] : false
    @user_time_slot = UserTimeSlot.includes(:user).find_by(user_id: params[:doctor_id])
  end

  private

  def check_role
    if current_user.has_role?(:pharmacist)
      redirect_to "/inventory/stores/284748001"
    elsif current_user.has_role?(:optician)
      redirect_to "/inventory/stores/50121007"
    end
  end

  def task_list_params
    params.permit(:comment, :creation_date, :completion_date, :user_id, :organisation_id, :is_complete)
  end
end
