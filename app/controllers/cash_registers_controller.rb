class CashRegistersController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html

  def new
    @cash_register_type_id = params[:typeid]
    @cash_register_type = params[:type]
    @userid = current_user.id
    @cash_register = CashRegister.new
    if params[:typeid].to_i == 440655000
      @appointmentid = params[:appointmentid]
      @appointment = Appointment.find(@appointmentid)
      @patientid = @appointment.patient.id
      @cash_register.appointment_id = @appointmentid
      @facility_id = @appointment.facility_id
    elsif params[:typeid].to_i == 440654001
      @admissionid = params[:admissionid]
      @admission = Admission.find(@admissionid)
      @patientid = @admission.patient.id
      @cash_register.admission_id = @admissionid
      @facility_id = @admission.facility_id
    end
    @cash_register.patient_id = @patientid
    @cash_register.user_id = @userid
    @total_cash_register_rows = 0

    if (params[:cash_register_template] != nil) then
      @template_cash_register_details = params[:cash_register_template]
      @template_cash_register_details = JSON.parse(@template_cash_register_details)

      @template_cash_register_details.each do |index, template_cash_register_detail|
        @total_cash_register_rows += 1
        @cash_register.cash_register_details.build(template_cash_register_detail)
      end
    else
      @total_cash_register_rows += 1
      1.times { @cash_register.cash_register_details.build }
    end

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def create
    params[:debug].present?
    @cash_register = CashRegister.new(cash_register_params)
    @cash_register.save
    if @cash_register.cash_register_type == "OPD"
      create_opd_cash_register_report
    elsif @cash_register.cash_register_type == "IPD"
      create_ipd_cash_register_report
    end
    @patient = Patient.find(params[:cash_register][:patient_id])
    @patient.update_attributes(patient_update_params)
    # model method for exact_age
    @patient.get_exact_age(@patient.age.to_i, @patient.age_month.to_i)

    @cash_register_details = params[:cash_register][:cash_register_details_attributes]
    add_non_existing_services(@cash_register_details, params[:cash_register][:cash_register_type], params[:cash_register][:cash_register_type_id])

    respond_to do |format|
      format.js {}
    end
  end

  def edit
    @cash_register = CashRegister.find_by(:id => params[:id])
    respond_to do |format|
      format.js {}
    end
  end

  def update
    @cash_register = CashRegister.find(params[:id])
    @patient = Patient.find(params[:cash_register][:patient_id])
    @patient.update_attributes(patient_update_params)
    # model method for exact_age
    @patient.get_exact_age(@patient.age.to_i, @patient.age_month.to_i)

    if @cash_register.cash_register_type == "OPD"
      find_edit_opd_cash_reg_report
    elsif @cash_register.cash_register_type == "IPD"
      find_edit_ipd_cash_reg_report
    end

    @cash_register.update(cash_register_update_params)

    if @cash_register.cash_register_type == "OPD"
      update_opd_cash_reg_report
    elsif @cash_register.cash_register_type == "IPD"
      update_ipd_cash_reg_report
    end

    @cash_register_details = params[:cash_register][:cash_register_details_attributes]
    add_non_existing_services(@cash_register_details, params[:cash_register][:cash_register_type], params[:cash_register][:cash_register_type_id])
    @patient_details = params[:cash_register][:patient]

    if params[:cash_register_details_for_delete] != ""
      @cash_register.cash_register_details.where(:id.in => params[:cash_register_details_for_delete].split(',')).delete
    end

    respond_to do |format|
      format.js {}
    end
  end

  def show
    @cash_register = CashRegister.find(params[:id])
    @cash_register_details = @cash_register[:cash_register_details]
    @patient = Patient.find_by(id: @cash_register.patient_id)
    @userid = current_user.id
    respond_to do |format|
      format.js {}
    end
  end

  def delete
  end

  def destroy
    @cash_register = CashRegister.where(:facility_id => current_facility.id)
    @cash_register.destroy
    @cash_register_template = CashRegisterTemplate.where(:user_id => current_user.id)
    @cash_register_template.destroy
    current_user.organisation.update_attributes(:cash_register_counter => 10000)

    DailyReport.where(facility_id: current_facility.id).each do |dr|
      dr.update_attributes(opd_cash_reg_transaction: 0.0, ipd_cash_reg_transaction: 0.0, opd_cash_register_ids: [], ipd_cash_register_ids: [])
    end

    respond_to do |format|
      format.js { render "cash_register_templates/destroy", :layout => false }
    end
  end

  def day_wise_earnings
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    @each_day_earnings = CashRegister.select("date(created_at) as date, sum(total) as total_earnings")
                                     .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                                     .group("date(created_at)")
  end

  def service_wise_earnings
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    each_service_earnings_by_day = CashRegisterDetail.select("date(created_at) as date, sum(unit_price*total_units) as total_earnings,label")
                                                     .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                                                     .group("date(created_at),label")
    @each_service_earnings = {};
    each_service_earnings_by_day.each do |single_earning|
      if !@each_service_earnings[single_earning[:label]].present?
        @each_service_earnings[single_earning[:label]] = {}
        # @each_service_earnings[single_earning[:label]]["each_day_details"] = {}
      end
      @each_service_earnings[single_earning[:label]][single_earning[:date]] = single_earning[:total_earnings]
      # logger.debug("adsfdsaf"+single_earning[:label])
    end
  end

  def add_non_existing_services(cash_register_details, service_type, service_type_id)
    cash_register_details.each do |index, cash_register_detail|
      if cash_register_detail[:id].nil?
        if !Service.where(name: cash_register_detail[:label], organisation_id: current_user.organisation.id).exists?
          @service = Service.new
          @service[:name] = cash_register_detail[:label]
          @service[:unit_cost] = cash_register_detail[:unit_price]
          @service[:default_units] = cash_register_detail[:total_units]
          @service[:organisation_id] = current_user.organisation.id
          @service[:service_type] = service_type
          @service[:service_type_id] = service_type_id
          @service[:is_custom] = "Y"
          @service.save
        end
      end
    end
  end

  private

  def cash_register_update_params
    params.require(:cash_register).permit(:user_id, :comments, :appointment_id, :admission_id, :cash_register_type_id, :cash_register_type, :patient_id, :total, :tax, :discount, :bill_number, cash_register_details_attributes: [:id, :label, :unit_price, :total_units])
  end

  def patient_update_params
    params[:cash_register].require(:patient).permit(:fullname, :mobilenumber, :age, :age_month, :gender, :address_1, :address_2, :city, :state, :pincode)
  end

  def cash_register_params
    params.require(:cash_register).permit(:user_id, :comments, :appointment_id, :admission_id, :cash_register_type_id, :cash_register_type, :patient_id, :facility_id, :total, cash_register_details_attributes: [:id, :label, :unit_price, :total_units]).merge(:bill_number => CommonHelper::get_cash_register_record_identifier(current_user))
  end

  def create_opd_cash_register_report
    @opd_cash_report = DailyReport.find_by(date: Date.current, facility_id: @cash_register.facility_id)
    if @opd_cash_report.nil?
      @opd_cash_report = DailyReport.new
      @opd_cash_report.opd_cash_register_ids = [@cash_register.id.to_s]
      @opd_cash_report.opd_cash_reg_transaction = params[:cash_register][:total].to_f
      @opd_cash_report.opd_cr_payment_received = params[:cash_register][:total].to_f
      @opd_cash_report.user_id = params[:cash_register][:user_id]
      @opd_cash_report.month = Date.current.month
      @opd_cash_report.year = Date.current.year
      @opd_cash_report.date = Date.current
      @opd_cash_report.facility_id = @cash_register.facility_id
      @opd_cash_report.save!
    else
      @opd_cash_today = @opd_cash_report.opd_cash_reg_transaction
      @cash_reg_ids = @opd_cash_report.opd_cash_register_ids << @cash_register.id.to_s
      @opd_cash_report.update_attributes(opd_cr_payment_received: @opd_cash_report.opd_cr_payment_received + params[:cash_register][:total].to_f, opd_cash_reg_transaction: @opd_cash_today.to_i + params[:cash_register][:total].to_f, opd_cash_register_ids: @cash_reg_ids)
    end
  end

  def create_ipd_cash_register_report
    @ipd_cash_report = DailyReport.find_by(date: Date.current, facility_id: @cash_register.facility_id)
    if @ipd_cash_report.nil?
      @ipd_cash_report = DailyReport.new
      @ipd_cash_report.ipd_cash_register_ids = [@cash_register.id.to_s]
      @ipd_cash_report.ipd_cash_reg_transaction = params[:cash_register][:total].to_f
      @ipd_cash_report.ipd_cr_payment_received = params[:cash_register][:total].to_f
      @ipd_cash_report.user_id = params[:cash_register][:user_id]
      @ipd_cash_report.month = Date.current.month
      @ipd_cash_report.year = Date.current.year
      @ipd_cash_report.date = Date.current
      @ipd_cash_report.facility_id = @cash_register.facility_id
      @ipd_cash_report.save!
    else
      @ipd_cash_today = @ipd_cash_report.ipd_cash_reg_transaction
      @cash_reg_ids = @ipd_cash_report.ipd_cash_register_ids << @cash_register.id.to_s
      @ipd_cash_report.update_attributes(ipd_cr_payment_received: @ipd_cash_report.ipd_cr_payment_received + params[:cash_register][:total].to_f, ipd_cash_reg_transaction: @ipd_cash_today.to_i + params[:cash_register][:total].to_f, ipd_cash_register_ids: @cash_reg_ids)
    end
  end

  def find_edit_opd_cash_reg_report
    @opd_cash_report = DailyReport.find_by(:opd_cash_register_ids.in => [params[:id]])
    @opd_cash_today = @opd_cash_report.opd_cash_reg_transaction - @cash_register.total
  end

  def update_opd_cash_reg_report
    @opd_cash_today = @opd_cash_today + @cash_register.total
    @opd_cash_report.update_attributes(opd_cash_reg_transaction: @opd_cash_today, opd_cr_payment_received: @opd_cash_today)
  end

  def find_edit_ipd_cash_reg_report
    @ipd_cash_report = DailyReport.find_by(:ipd_cash_register_ids.in => [params[:id]])
    @ipd_cash_today = @ipd_cash_report.ipd_cash_reg_transaction - @cash_register.total
  end

  def update_ipd_cash_reg_report
    @ipd_cash_today = @ipd_cash_today + @cash_register.total
    @ipd_cash_report.update_attributes(ipd_cash_reg_transaction: @ipd_cash_today, ipd_cr_payment_received: @ipd_cash_today)
  end
end
