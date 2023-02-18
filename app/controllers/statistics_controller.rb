class StatisticsController < ApplicationController
  before_action :authorize

  before_action :authorize_onboard
  before_action :authenticate_admin_user, only: [:index]
  layout "loggedin"

  before_action :start_end_date, only: [:index, :data_content, :print]

  def index
    facility_currency_ids = current_facility.currency_ids + [current_facility.currency_id]
    @facility_currencies = Currency.where(:id.in => facility_currency_ids)
    currency_id = (params[:currency_id] || current_facility.currency_id)
    @currency = Currency.find_by(id: currency_id)
    # @users = User.where(facility_ids: current_facility.id.to_s, role_ids: 158965000)

    # @invoice_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date)+1)
    # @invoice_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date)+1)

    @tax_collected = TaxCollected.where(facility_id: current_facility.id.to_s, :date.gte => @start_date, :date.lte => Date.parse(@end_date) + 1)
    tax_calculation

    @payment_received = Invoice::PaymentReceived.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lte => Date.parse(@end_date) + 1, is_active: true)
    payment_received_breakup

    @advance_payment_opd = AdvancePayment.where(type: "OPD", facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lte => Date.parse(@end_date) + 1)
    @advance_payment_ipd = AdvancePayment.where(type: "IPD", facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lte => Date.parse(@end_date) + 1)

    @daily_reports = DailyReport.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lte => @end_date).order('date ASC')
    inventory_finance_report

    unless current_facility.show_finances?
      respond_to do |format|
        format.html { redirect_to '/' }
      end
    end
  end

  def data_content
    currency_id = (params[:currency_id] || current_facility.currency_id)
    @currency = Currency.find_by(id: currency_id)
    @filter = params[:filter]
    if @filter == "All"
      # @invoice_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date)+1)
      # @invoice_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date)+1)

      @tax_collected = TaxCollected.where(facility_id: current_facility.id.to_s, :date.gte => @start_date, :date.lte => Date.parse(@end_date) + 1)
      tax_calculation

      @payment_received = Invoice::PaymentReceived.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lte => Date.parse(@end_date) + 1, is_active: true)
      payment_received_breakup

      @advance_payment_opd = AdvancePayment.where(type: "OPD", facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lte => Date.parse(@end_date) + 1)
      @advance_payment_ipd = AdvancePayment.where(type: "IPD", facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lte => Date.parse(@end_date) + 1)

      @daily_reports = DailyReport.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lte => @end_date).order('date ASC')
      inventory_finance_report
    elsif @filter == "Credit"
      @payment_pending = Invoice::PaymentPending.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lt => Date.parse(@end_date) + 1, is_active: true)
      @received_from = @payment_pending.pluck(:received_from).uniq
    elsif @filter == "OPD"
      if @start_date == @end_date
        @invoice_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date) + 1)
        @cash_reg_app = CashRegister.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.parse(@start_date), :created_at.lt => Date.parse(@end_date) + 1, cash_register_type: "OPD")
      else
        @daily_reports = DailyReport.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lte => @end_date).order('date ASC')
      end
    elsif @filter == "IPD"
      if @start_date == @end_date
        @invoice_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date) + 1)
        @cash_reg_adm = CashRegister.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.parse(@start_date), :created_at.lt => Date.parse(@end_date) + 1, cash_register_type: "IPD")
      else
        @daily_reports = DailyReport.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lte => @end_date).order('date ASC')
      end
    elsif @filter == "Inventory"
      inventory_finance_report
    elsif @filter == "Tax"
      # @tax_collected = TaxCollected.where(facility_id: current_facility.id.to_s, :date.gte => @start_date, :date.lt => Date.parse(@end_date)+1)
      # tax_calculation
      @invoice_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date) + 1, :tax_breakup.nin => [[]])
      @invoice_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date) + 1, :tax_breakup.nin => [[]])
      @optical = Invoice::Inventories::Department::OpticalInvoice.where(:facility_id => current_facility.id.to_s, currency_id: currency_id, :created_at.gte => Date.parse(@start_date), :created_at.lt => Date.parse(@end_date) + 1, :tax_breakup.nin => [[]])
      @pharmacy = Invoice::Inventories::Department::PharmacyInvoice.where(:facility_id => current_facility.id.to_s, currency_id: currency_id, :created_at.gte => Date.parse(@start_date), :created_at.lte => Date.parse(@end_date) + 1, :tax_breakup.nin => [[]])
    end
    respond_to do |format|
      # if @start_date == @end_date
      # format.html { render partial: "statistics/data_content_daily", layout: false }
      # else
      format.js { render "statistics/data_content.js.erb" }
      # end
    end
  end

  def print_setting
  end

  def print
    currency_id = (params[:currency_id] || current_facility.currency_id)
    @currency = Currency.find_by(id: currency_id)
    if params[:flag] == 'opd_daily_view'
      @invoice_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date) + 1)
    elsif params[:flag] == 'opd_multidate_view'
      @daily_reports = DailyReport.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lte => @end_date).order('date ASC')
    elsif params[:flag] == 'ipd_daily_view'
      @invoice_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :created_at.gte => @start_date, :created_at.lt => Date.parse(@end_date) + 1)
    elsif params[:flag] == 'ipd_multidate_view'
      @daily_reports = DailyReport.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lte => @end_date).order('date ASC')
    elsif params[:flag] == 'opd_cr_daily_view'
      @cash_reg_app = CashRegister.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.parse(@start_date), :created_at.lt => Date.parse(@end_date) + 1, cash_register_type: "OPD")
    elsif params[:flag] == 'ipd_cr_daily_view'
      @cash_reg_adm = CashRegister.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.parse(@start_date), :created_at.lt => Date.parse(@end_date) + 1, cash_register_type: "IPD")
    elsif params[:flag] == 'pharmacy_daily_view'
      inventory_finance_report
    elsif params[:flag] == 'optical_daily_view'
      inventory_finance_report
    elsif params[:flag] == 'pharmacy_multidate_view'
      inventory_finance_report
    elsif params[:flag] == 'optical_multidate_view'
      inventory_finance_report
    elsif params[:flag] == 'inventory_checkout_view'
      inventory_finance_report
    elsif params[:flag] == 'creditor_list'
      @payment_pending = Invoice::PaymentPending.where(facility_id: current_facility.id.to_s, currency_id: currency_id, :date.gte => @start_date, :date.lt => Date.parse(@end_date) + 1, is_active: true)
      @received_from = @payment_pending.pluck(:received_from).uniq
    elsif params[:flag] == 'creditor_detail_list'
      @received_from = params[:received_from]
      if params[:creditor] == 'patient'
        @patient = Patient.find_by(id: params[:received_from])
        @creditor = @patient.fullname
      elsif params[:creditor] == 'contact'
        @payer_master = PayerMaster.find_by(id: params[:received_from])
        @creditor = @payer_master.display_name
      end
      @payment_pending = Invoice::PaymentPending.includes(:invoice).where(received_from: @received_from, is_active: true)
    end

    @checked_fields = params[:checked_fields].to_s.split(",")
    print_flags

    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]

    respond_to do |format|
      format.pdf { render :template => "statistics/print", :pdf => "Reports", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => false, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def creditors_pending_payment
    @received_from = params[:received_from]
    if params[:creditor] == 'patient'
      @patient = Patient.find_by(id: params[:received_from])
      @creditor = @patient.fullname
    elsif params[:creditor] == 'contact'
      @payer_master = PayerMaster.find_by(id: params[:received_from])
      @creditor = @payer_master.display_name
    end
    @payment_pending = Invoice::PaymentPending.includes(:invoice).where(received_from: @received_from, is_active: true)
  end

  private

  def authenticate_admin_user
    department_ids = current_user.department_ids
    if department_ids.present?
      if department_ids.include?("224608005")
        # custom_check_for_lockup
      else
        redirect_to user_department_url(current_user)
      end
    else
      redirect_to '/'
    end
  end

  def custom_check_for_lockup
    multi_auth = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id)).try(:multi_auth)
    return unless multi_auth
    return unless respond_to?(:lockup) && lockup_codeword
    return if cookies[:lockup].present? && cookies[:lockup] == lockup_codeword.to_s.downcase

    if request.xhr?
      respond_to do |format|
        format.js { render inline: "location.reload();" }
      end
    else
      redirect_to lockup.unlock_path(
        return_to: request.fullpath.split('?lockup_codeword')[0],
        lockup_codeword: params[:lockup_codeword],
      )
    end
  end

  def inventory_finance_report
    currency_id = (params[:currency_id] || current_facility.currency_id)
    @currency = Currency.find_by(id: currency_id)
    @optical = Invoice::Inventories::Department::OpticalInvoice.where(:facility_id => current_facility.id.to_s, currency_id: currency_id, :created_at.gte => Date.parse(@start_date), :created_at.lt => Date.parse(@end_date) + 1).order_by('created_at asc')
    grouped_data_optical = @optical.group_by { |item| item.created_at.to_date }
    @optical_dates = grouped_data_optical.keys.map { |i| i.strftime("%d %b '%y") }
    @optical_total = grouped_data_optical.values.map { |i| i.map { |j| j.total }.sum }
    # @optical_tax = grouped_data_optical.values.map{|i| i.map{|j| j.tax_breakup}}

    @optical_return = @invoices = Invoice::Inventories::Department::OpticalReturn.where(:facility_id => current_facility.id.to_s, :created_at.gte => @start_date, :created_at.lt => @end_date).order_by('created_at asc')

    @pharmacy = Invoice::Inventories::Department::PharmacyInvoice.where(:facility_id => current_facility.id.to_s, currency_id: currency_id, :created_at.gte => Date.parse(@start_date), :created_at.lte => Date.parse(@end_date) + 1)
    grouped_data_pharmacy = @pharmacy.group_by { |item| item.created_at.to_date }
    @pharmacy_dates = grouped_data_pharmacy.keys.map { |i| i.strftime("%d %b '%y") }
    @pharmacy_total = grouped_data_pharmacy.values.map { |i| i.map { |j| j.total }.sum }
    # @pharmacy_tax = grouped_data_pharmacy.values.map{|i| i.map{|j| j.tax_breakup}}

    @pharmacy_return = Invoice::Inventories::Department::PharmacyReturn.where(:facility_id => current_facility.id.to_s, :created_at.gte => @start_date, :created_at.lt => @end_date).order_by('created_at asc')
    grouped_data_pharmacy_return = @pharmacy_return.group_by { |item| item.created_at.to_date }
    @pharmacy_dates_return = grouped_data_pharmacy_return.keys
    @pharmacy_total_return = grouped_data_pharmacy_return.values.map { |i| i.map { |j| j.total }.sum }

    @department = Invoice::Inventories::DepartmentInvoice.where(:facility_id => current_facility.id.to_s, :created_at.gte => @start_date, :created_at.lt => @end_date).order_by('created_at asc')

    @inventory_checkout = Inventory::CheckoutLog.where(facility_id: current_facility.id.to_s, :created_at.gte => Date.parse(@start_date), :created_at.lte => Date.parse(@end_date) + 1).group_by { |item| item.created_at.to_date }
    @checkout_dates = @inventory_checkout.keys.map { |i| i.strftime("%d %b '%y") }
    checkout_array = @inventory_checkout.values.map { |i| i.map { |j| j.items.pluck(:quantity).sum } }
    @checkout_total = checkout_array.map { |i| i.sum }
    @optical_checkout = Array.new
    @inventory_checkout.keys.each do |date|
      checkout = Inventory::CheckoutLog.where(facility_id: current_facility.id.to_s, department_id: "50121007", :created_at.gte => date, :created_at.lt => date + 1)
      if checkout.count > 0
        checkout_item = 0
        checkout.each do |checkout|
          checkout_item = checkout_item + checkout.items.pluck(:quantity).sum
        end
        @optical_checkout << checkout_item
      else
        @optical_checkout << 0
      end
    end
    # @other_checkout = Array.new
    # @inventory_checkout.keys.each do |date|
    #   checkout = Inventory::CheckoutLog.find_by(facility_id: current_facility.id.to_s,:department_id.in=> ["261904005","224608005","309988001_387713003","225746001","309989009_387713003","309988001_387713003","309964003","309989009_73770003","309989009_440654001","309989009_440655000", "309988001_73770003","309988001_440654001","309988001_440655000"],:created_at.gte => date,:created_at.lt => date + 1)
    #   if checkout
    #     @other_checkout << checkout.items.pluck(:quantity).sum
    #   else
    #     @other_checkout << 0
    #   end
    # end

    @pharmacy_checkout = Array.new
    @inventory_checkout.keys.each do |date|
      checkout = Inventory::CheckoutLog.where(facility_id: current_facility.id.to_s, department_id: "284748001", :created_at.gte => date, :created_at.lt => date + 1)
      if checkout.count > 0
        checkout_item = 0
        checkout.each do |checkout|
          checkout_item = checkout_item + checkout.items.pluck(:quantity).sum
        end
        @pharmacy_checkout << checkout_item
      else
        @pharmacy_checkout << 0
      end
    end
  end

  def get_communication_details
    appointment_sms = CommunicationDetail.where(facility_id: current_facility.id.to_s, :communication_info => "appointment", :communication_type => "sms", :created_at.gte => @start_date, :created_at.lt => @end_date).count
    followup_sms = CommunicationDetail.where(facility_id: current_facility.id.to_s, :communication_info => "followup", :communication_type => "sms", :created_at.gte => @start_date, :created_at.lt => @end_date).count
    visit_sms = CommunicationDetail.where(facility_id: current_facility.id.to_s, :communication_info => "visit", :communication_type => "sms", :created_at.gte => @start_date, :created_at.lt => @end_date).count
    overdue_sms = CommunicationDetail.where(facility_id: current_facility.id.to_s, :communication_info => "overdue", :communication_type => "sms", :created_at.gte => @start_date, :created_at.lt => @end_date).count
    discharge_sms = CommunicationDetail.where(facility_id: current_facility.id.to_s, :communication_info => "discharge", :communication_type => "sms", :created_at.gte => @start_date, :created_at.lt => @end_date).count
    birthday_sms = CommunicationDetail.where(facility_id: current_facility.id.to_s, :communication_info => "birthday", :communication_type => "sms", :created_at.gte => @start_date, :created_at.lt => @end_date).count
    @communication_info_array = [appointment_sms, followup_sms, visit_sms, overdue_sms, discharge_sms, birthday_sms]
    @communication_type = ["Appointment", "Followup", "Visit Ack", "Overdue", "Discharge", "Birthday"]
  end

  def start_end_date
    params[:start_date] = params[:end_date] if params[:start_date].blank?
    params[:end_date] = params[:start_date] if params[:end_date].blank?

    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      if start_date != "" && end_date != ""
        if start_date > end_date
          @end_date = start_date.strftime('%d/%m/%Y')
          @start_date = end_date.strftime('%d/%m/%Y')
        else
          @start_date = start_date.strftime('%d/%m/%Y')
          @end_date = end_date.strftime('%d/%m/%Y')
        end
      elsif start_date != ""
        @start_date = start_date.strftime('%d/%m/%Y')
        @end_date = start_date.strftime('%d/%m/%Y')
      elsif end_date != ""
        @start_date = end_date.strftime('%d/%m/%Y')
        @end_date = end_date.strftime('%d/%m/%Y')
      else
        no_start_end_date
      end
    else
      no_start_end_date
    end
  end

  def no_start_end_date
    unless params[:time_period] == "beginning"
      @time_period = get_time_period(params[:time_period])
      @start_date = (Date.current - @time_period).strftime("%d/%m/%Y")
      @end_date = Date.current.strftime("%d/%m/%Y")
    else
      @start_date = current_facility.created_at.strftime("%d/%m/%Y")
      @end_date = Date.current.strftime("%d/%m/%Y")
    end
  end

  def get_time_period(time)
    case time
    when 'today'
      0
    when 'week'
      6
    when 'month'
      30
    when '3months'
      91
    when '6months'
      183
    when '1year'
      365
    when 'beginning'
      365 * 5
    else
      0
    end
  end

  def payment_received_breakup
    @payment_received_cash = @payment_received.where(:mode_of_payment.in => ['Cash', 'Cash & Card']).pluck(:cash).map(&:to_f).sum
    @payment_received_card = @payment_received.where(:mode_of_payment.in => ['Card', 'Cash & Card']).pluck(:card).map(&:to_f).sum
    @payment_received_cheque = @payment_received.where(mode_of_payment: 'Cheque').pluck(:amount).map(&:to_f).sum
    @payment_received_transfer = @payment_received.where(mode_of_payment: 'Online Transfer').pluck(:amount).map(&:to_f).sum
    @payment_received_others = @payment_received.where(mode_of_payment: 'Others').pluck(:amount).map(&:to_f).sum
  end

  def tax_calculation
    @tax_collected_total = 0
    @tax_details_array = []
    @tax_collected.each do |tax_collected|
      tax_details = tax_collected.tax_details
      @tax_collected_total = @tax_collected_total + tax_details.pluck(:total).sum

      tax_details.each do |tax_detail|
        @tax_details_array.push(tax_detail.attributes)
      end
    end

    @cgst = @tax_details_array.inject(0) { |sum, x| (x[:type] == "CGST") ? sum += x[:total].to_f : sum }
    @sgst = @tax_details_array.inject(0) { |sum, x| (x[:type] == "SGST") ? sum += x[:total].to_f : sum }
    @igst = @tax_details_array.inject(0) { |sum, x| (x[:type] == "IGST") ? sum += x[:total].to_f : sum }
    @utgst = @tax_details_array.inject(0) { |sum, x| (x[:type] == "UTGST") ? sum += x[:total].to_f : sum }
    @cess = @tax_details_array.inject(0) { |sum, x| (x[:type] == "Cess") ? sum += x[:total].to_f : sum }
    @others = @tax_details_array.inject(0) { |sum, x| (x[:type] == "Others") ? sum += x[:total].to_f : sum }
  end

  def print_flags
    @patient_id = @checked_fields.include?("patient_id")
    @mr_no = @checked_fields.include?("mr_no")
    @invoice_id = @checked_fields.include?("invoice_id")
    @total = @checked_fields.include?("total")
    @tax = @checked_fields.include?("tax")
    @discount = @checked_fields.include?("discount")
    @advance = @checked_fields.include?("advance")
    @amount = @checked_fields.include?("amount")
    @received = @checked_fields.include?("received")
    @pending = @checked_fields.include?("pending")

    @cash_register = @checked_fields.include?("cash_register")
    @invoice = @checked_fields.include?("invoice")

    @cash_register_id = @checked_fields.include?("cash_register_id")

    @item = @checked_fields.include?("item")
    @item_mrp = @checked_fields.include?("item_mrp")
  end
end

# OPD Finance

# 1.Invoice Total Daily,weekly etc
# 2.total by service
# 3.total by item
# 4.Total invoice count
# 5.Cash an card total
# 6.Cash register
# 7.Average invoice amount weekly,monthly

# IPD finance
# 1.Insurance
# 2.Insurance money remaining vs money in hand

# opd appointment
# 1.by appointment types
# 2.
# 3.

# Patient
# 1.BY Age group,Gender
# 2.By Opd,ipd,ot
# 3.new vs registered
# 4.

# Inventory finance
# 1.Item most sold
# 2.Total inventory count
# 3.Department wise inventory usuage
# issue: total only save in optical and pharmacy
