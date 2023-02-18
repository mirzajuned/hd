class DashboardController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  layout "loggedin"

  before_action :initial_params, only: [:index, :show]

  def index
    # Task List
    @newtask = TaskList.new()
    @tasks = TaskList.where(organisation_id: current_user.organisation_id).order(:position => :asc)

    # Holiday Plan
    @holiday_plans = HolidayPlan.where(user_id: current_user.id, start_date: DateTime.now..(DateTime.now+100).in_time_zone.utc )
    b = []
    b = @holiday_plans.filter { |data| 
      data.end_date.day == DateTime.now.day && Time.parse( data.start_time.strftime('%H:%M')) < Time.parse(Time.now.strftime('%H:%M')).utc 
    }
    @holiday_plans = @holiday_plans - b
    @holiday_plans_past = HolidayPlan.where(user_id: current_user.id) - @holiday_plans

    @holiday_plans.sort! { |a,b| 
       a_start = a.start_date.to_s + ' ' + a.start_time.strftime("%I:%M %p").to_s
       b_start = b.start_date.to_s + ' ' + b.start_time.strftime("%I:%M %p").to_s

        DateTime.parse(a_start).utc <=>  DateTime.parse(b_start).utc
    }
    @holiday_plans_past.sort! { |a,b| 
     a_start = a.start_date.to_s + ' ' + a.start_time.strftime("%I:%M %p").to_s
     b_start = b.start_date.to_s + ' ' + b.start_time.strftime("%I:%M %p").to_s

       DateTime.parse(b_start).utc <=> DateTime.parse(a_start).utc 
    }
    # Daily Finance Reports
    @invoice_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1).order(currency_symbol: :desc)
    @invoice_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1).order(currency_symbol: :desc)
    @invoice_pharmacy = Invoice::Inventories::Department::PharmacyInvoice.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1).order(currency_symbol: :desc)
    @invoice_optical = Invoice::Inventories::Department::OpticalInvoice.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.current, :created_at.lt => Date.current + 1).order(currency_symbol: :desc)

    # To check whether they exist
    @pharmacy = Inventory::Department.find_by(facility_id: current_facility.id.to_s, department_id: 284748001)
    @optical = Inventory::Department.find_by(facility_id: current_facility.id.to_s, department_id: 50121007)
    @dashboard_settings = DashboardSetting.find_by(user_id: current_user.id)
  end

  def show
    # Main Dashboard
    @current_facility = current_facility
    @current_user = current_user
    options = {}
    if @facility
      @all_facilities = @facility.to_a # for All Facility Option
      options = options.merge({ facility_id: @facility.id })
    else
      @all_facilities = User.find_by(id: @current_user.id).facilities.where(is_active: true) # for All Facility Option
      options = options.merge({ :facility_id.in => @all_facilities.pluck(:id) })
    end
    if @user
      # options = options.merge({user_id: @user.id})
      # appointment_options = options.merge({appointmentdate: @current_date, appointmentstatus: 416774000,doctor: @user.id})
      appointment_options = options.merge({ appointment_date: @current_date, :current_state.nin => ["Deleted"], consulting_doctor_id: @user.id })
      admission_options = options.merge({ isdischarged: false, is_deleted: false, admissiondate: @current_date, doctor: @user.id })
      admitted_options = options.merge({ isdischarged: false, is_deleted: false, patient_arrived: true, doctor: @user.id })
      discharge_options = options.merge({ isdischarged: true, dischargedate: @current_date, doctor: @user.id })
      ot_options = options.merge({ otdate: @current_date, is_deleted: false, surgeonname: @user.id })
    else
      # appointment_options = options.merge({appointmentdate: @current_date, appointmentstatus: 416774000})
      appointment_options = options.merge({ appointment_date: @current_date, :current_state.nin => ["Deleted"] })
      admission_options = options.merge({ isdischarged: false, is_deleted: false, admissiondate: @current_date })
      admitted_options = options.merge({ isdischarged: false, is_deleted: false, patient_arrived: true })
      discharge_options = options.merge({ isdischarged: true, dischargedate: @current_date })
      ot_options = options.merge({ otdate: @current_date, is_deleted: false })
    end

    @appointment = AppointmentListView.where(appointment_options).limit(@count).order(appointment_start_time: @sort_by.parameterize.to_sym)
    @appointment_by_facility = @appointment.group_by(&:facility_id)
    @appointment_facilities = Facility.where(:id.in => @appointment_by_facility.try(:keys)).group_by(&:id)

    @appt_worlflow = OpdClinicalWorkflow.where(:appointment_id.in => @appointment.pluck(:appointment_id).map(&:to_s))

    @admission = Admission.includes(:patient).where(admission_options).order(admissiontime: @sort_by.parameterize.to_sym)
    @admission_by_facility = @admission.group_by(&:facility_id)
    @admission_facilities = Facility.where(:id.in => @admission_by_facility.try(:keys)).group_by(&:id)

    @admitted = Admission.includes(:patient).where(admitted_options).order(admissiontime: @sort_by.parameterize.to_sym)
    @admitted_by_facility = @admitted.group_by(&:facility_id)
    @admitted_facilities = Facility.where(:id.in => @admitted_by_facility.try(:keys)).group_by(&:id)

    @discharged = Admission.includes(:patient).where(discharge_options).order(dischargetime: @sort_by.parameterize.to_sym)
    @discharged_by_facility = @discharged.group_by(&:facility_id)
    @discharged_facilities = Facility.where(:id.in => @discharged_by_facility.try(:keys)).group_by(&:id)

    @ot = OtSchedule.includes(:patient).where(ot_options).order(ottime: @sort_by.parameterize.to_sym)
    @ot_by_facility = @ot.group_by(&:facility_id)
    @ot_facilities = Facility.where(:id.in => @ot_by_facility.try(:keys)).group_by(&:id)

    @dashboard_settings = DashboardSetting.find_by(user_id: @current_user.id)
    if @dashboard_settings
      @dashboard_settings.update_attributes(default_facility: (@facility.try(:id) || 0), default_user: (@user.try(:id) || 0), show: @count, sort: @sort_by)
    else
      @dashboard_settings = DashboardSetting.create(user_id: @current_user.id, facility_id: @current_facility.id, default_facility: (@facility.try(:id) || 0), default_user: (@user.try(:id) || 0), show: @count, sort: @sort_by)
    end
  end

  def get_users
    if (current_user.role_ids.include? 158965000) && !(current_user.role_ids.include? 160943002)
      @user = [[current_user.fullname, current_user.id]]
      @show_all = false
    else
      if params[:facility_id].to_i != 0
        options = {facility_ids: params[:facility_id], role_ids: 158965000}
      else
        options = {organisation_id: current_user.organisation_id, role_ids: 158965000}
      end
      # unless current user is admin/owner
      unless (current_user.role_ids.include? 160943002) || (current_user.role_ids.include? 6868009)
        options = options.merge({is_active: true})
      end
      @user = User.where(options).pluck("fullname", "id")
      @show_all = true
    end
    # render json: @user.to_json
    render json: { "user": @user, 'show_all': @show_all, 'active_user': params[:user_id] }
  end

  private

  def initial_params
    if params[:current_date].present?
      @current_date = Date.parse(params[:current_date])
    else
      @current_date = Date.current
    end
    if params[:facility_id]
      if params[:facility_id].to_i != 0
        @facility = Facility.find(params[:facility_id])
      else
        @facility = nil
      end
    else
      @facility = current_facility
    end
    if params[:user_id]
      if params[:user_id].to_i != 0
        @user = User.find(params[:user_id])
      else
        @user = nil
      end
    else
      @user = current_user
    end
    @sort_by = params[:sort]
    @count = params[:count]
  end
end

# User.where(user_selected_url: '/main/dashboard').update_all(user_selected_url: '/dashboard')
