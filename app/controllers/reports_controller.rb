class ReportsController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  layout 'backbone_reports'

  def index
    facility_id = params[:facility_id]
    @facilities = []

    current_user.organisation.facilities.where(is_active: true).each do |f|
      @facilities.push(f)
    end

    time_period = params[:time_period]

    days = get_time_period(time_period)

    if params[:report_to].present? && params[:report_from].present?
      report_to = Date.parse(params[:report_to])
      report_from = Date.parse(params[:report_from])
      @reports = DailyReport.where(facility_id: current_facility.id, :date.gte => report_to,
                                   :date.lt => report_from + 1).order_by('date asc')
    else

      @reports = DailyReport.where(facility_id: current_facility.id,
                                   :date.gte => (Date.current - days)).order_by('date asc')
    end
    respond_to do |format|
      format.html {}
      format.js {}
      format.json { render json: @reports.as_json }
    end
  end

  def daily_reports
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    # facility_id = params[:facility_id]
    current_date = if params[:report_to].present? && params[:report_from].present?
                     Date.parse(params[:report_to]) || Date.parse(params[:report_from])
                   else
                     Date.current
                   end
    types = [
      'Invoice::Opd',
      'Invoice::Ipd',
      'Invoice::Insurance',
      'Invoice::Inventories::Department::OpticalInvoice',
      'Invoice::Inventories::Department::PharmacyInvoice'
    ]

    # Needed for Pharmacy/Optical
    @today_listx = Invoice.where(:_type.in => types, facility_id: current_facility.id, :created_at.gte => current_date,
                                 :created_at.lt => current_date + 1, is_draft: false, is_deleted: false)
    @today_listy = Invoice.where(:_type.in => types, facility_id: current_facility.id.to_s,
                                 :created_at.gte => current_date, :created_at.lt => current_date + 1, is_draft: false, 
                                 is_deleted: false)
    @cash_reg_app = CashRegister.where(facility_id: current_facility.id.to_s, :created_at.gte => current_date,
                                       :created_at.lt => current_date + 1, cash_register_type: 'OPD')
    @cash_reg_adm = CashRegister.where(facility_id: current_facility.id.to_s, :created_at.gte => current_date,
                                       :created_at.lt => current_date + 1, cash_register_type: 'IPD')
    # @services = Invoice::ServiceList.where(facility_id: current_facility.id.to_s)
    @today_list = @today_listx + @today_listy + @cash_reg_app + @cash_reg_adm
  end

  def inventory_finance_report
    time_period = params[:time_period]
    days =  get_time_period(time_period)

    types = [
      'Invoice::Inventories::Department::OpticalInvoice',
      'Invoice::Inventories::Department::OpticalReturn',
      'Invoice::Inventories::Department::PharmacyInvoice',
      'Invoice::Inventories::DepartmentInvoice',
      'Invoice::Inventories::Department::PharmacyReturn'
    ]

    if params[:report_to].present? && params[:report_from].present?
      report_to = Date.parse(params[:report_to])
      report_from = Date.parse(params[:report_from])
      @invoices = Invoice.where(:_type.in => types, :facility_id => current_facility.id, :created_at.gte => report_to,
                                :created_at.lt => report_from + 1, is_draft: false, is_deleted: false).order_by('date asc')
    else
      @invoices = Invoice.where(:_type.in => types, :facility_id => current_facility.id,
                                :created_at.gte => (Date.current - days.days), is_draft: false, is_deleted: false).order_by('date asc')
    end

    respond_to do |format|
      # format.json { render json: @invoices.to_json }
      format.json {}
    end
  end

  def central_inventory_report
    time_period = params[:time_period]
    days = get_time_period(time_period)

    if params[:report_to].present? && params[:report_from].present?
      report_to = Date.parse(params[:report_to])
      report_from = Date.parse(params[:report_from])
      @invoices = Inventory::CheckoutLog.where(:facility_id => current_facility.id, :created_at.gte => report_to,
                                               :created_at.lt => report_from + 1).order_by('created_at asc')
    else
      @invoices = Inventory::CheckoutLog.where(:facility_id => current_facility.id,
                                               :created_at.gte => (Date.current - days.days)).order_by('created_at asc')
    end

    respond_to do |format|
      # format.json { render json: @invoices.to_json }
      format.json {}
    end
  end

  def referrals
    facility_id = params[:facility_id]
    @patient = Patient.where(:reg_hosp_ids.in => [current_user.organisation_id.to_s])
    @ref_doc_ids = @patient.pluck(:referring_doctor_id)
    @ref_doc_hash = Hash.new(0)
    @ref_doc_ids.each do |v|
      @ref_doc_hash[v] += 1
    end
    @ref_doc_hash = @ref_doc_hash.except!(nil)
    @ref_doc_array = []
    @ref_doc_hash.each do |key, value|
      doctor = ReferringDoctor.find_by(id: key)
      next unless doctor

      temp_doctor_details = { id: doctor.id, name: doctor.name, mobile: doctor.mobile_number,
                              specality: doctor.speciality, email: doctor.email,
                              hospital: doctor.hospital_name, count: value }
      @ref_doc_array << temp_doctor_details
    end
    # @ref_doc_name_hash = {}
    # @ref_doc_hash.each do |k,v|
    #   unless ReferringDoctor.find(k).nil?
    #     @ref_doc_name_hash[ReferringDoctor.find(k).name] = v
    #   end
    # end
    respond_to do |format|
      format.json { render json: @ref_doc_array.as_json }
    end
  end

  def communication
    facility_id = params[:facility_id]
    time_period = params[:time_period]

    days = get_time_period(time_period)

    # NEED TO ADD FACILITY ID HERE
    if params[:report_to].present? && params[:report_from].present?
      report_to = Date.parse(params[:report_to])
      report_from = Date.parse(params[:report_from])
      @communication_info_array = CommunicationDetail.where(organisation_id: current_user.organisation_id,
                                                            :communication_date.gte => report_to,
                                                            :communication_date.lt => report_from + 1)
                                                     .order_by('communication_date asc')
    else
      @communication_info_array = CommunicationDetail.where(organisation_id: current_user.organisation_id,
                                                            :communication_date.gte => (Time.current - days.days))
                                                     .order_by('communication_date acs')
    end
    # @communication_info_hash =Hash.new(0)
    # communication_info_array.each do |v|
    #   @communication_info_hash[v]+=1
    # end
    respond_to do |format|
      # format.json { render json: @communication_info_hash }
      format.json { render json: @communication_info_array }
    end
  end

  def daily_advance_report
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @facility = current_facility.id
    @organisation = current_user.organisation
    @datepicker_date = if params[:date] == 'Today'
                         Date.current
                       else
                         Date.parse(params[:date])
                       end
    @title = 'Patient Advance'
    @total_list = AdvancePayment.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date,
                                       :created_at.lt => @datepicker_date + 1, is_deleted: false)
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]

    respond_to do |format|
      format.pdf do
        render template: 'reports/print_advance_report.pdf.erb', pdf: '', layout: 'pdfgen.html.erb',
               viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true,
               show_as_html: params[:debug].present?, header: { spacing: 4 }, footer: { spacing: 10 },
               orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10,
                                                   right: @print_settings[0]['right_margin'].to_f * 10,
                                                   top: @print_settings[0]['header_height'].to_f,
                                                   bottom: @print_settings[0]['footer_height'].to_f }
      end
    end
  end

  def daily_refund_report
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @facility = current_facility.id
    @organisation = current_user.organisation
    @datepicker_date = if params[:date] == 'Today'
                         Date.current
                       else
                         Date.parse(params[:date])
                       end
    @title = 'Patient Refund'
    @total_list = RefundPayment.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date,
                                      :created_at.lt => @datepicker_date + 1, is_deleted: false)
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf do
        render template: 'reports/print_refund_report.pdf.erb', pdf: '', layout: 'pdfgen.html.erb',
               viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true,
               show_as_html: params[:debug].present?, header: { spacing: 4 }, footer: { spacing: 10 },
               orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10,
                                                   right: @print_settings[0]['right_margin'].to_f * 10,
                                                   top: @print_settings[0]['header_height'].to_f,
                                                   bottom: @print_settings[0]['footer_height'].to_f }
      end
    end
  end

  def daily_collection_report
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @facility = current_facility.id
    @organisation = current_user.organisation
    @datepicker_date = if params[:date] == 'Today'
                         Date.current
                       else
                         Date.parse(params[:date])
                       end
    if params[:location] == "My Collection"
      @title = 'Collection By User'
      @total_list = Finance::CollectionTransactionData.where(facility_id: @facility.to_s, :receipt_date.gte => @datepicker_date, :receipt_date.lt => @datepicker_date + 1, user_id: current_user.id, is_deleted: false).order_by('receipt_time ASC')
    else
      @title = 'Collection By All Users'
      @total_list = Finance::CollectionTransactionData.where(facility_id: @facility.to_s, :receipt_date.gte => @datepicker_date, :receipt_date.lt => @datepicker_date + 1, is_deleted: false).order_by('receipt_time ASC')
    end
    @total_list = @total_list.group_by(&:user_id)

    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf do
        render template: 'reports/print_collection_report.pdf.erb', pdf: '', layout: 'pdfgen.html.erb',
               viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true,
               show_as_html: params[:debug].present?, header: { spacing: 4 }, footer: { spacing: 10 },
               orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10,
                                                   right: @print_settings[0]['right_margin'].to_f * 10,
                                                   top: @print_settings[0]['header_height'].to_f,
                                                   bottom: @print_settings[0]['footer_height'].to_f }
      end
    end
  end

  def daily_report
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @facility = current_facility.id
    @organisation = current_user.organisation
    @datepicker_date = if params[:date] == 'Today'
                         Date.current
                       else
                         Date.parse(params[:date])
                       end

    if params[:location] == 'OPD Invoice'
      @title = params[:location]
      @total_list = Invoice::Opd.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date,
                                       :created_at.lt => @datepicker_date + 1, is_draft: false, is_deleted: false)
      @maintotalinvoice = @total_list.pluck(:net_amount)
    elsif params[:location] == 'IPD Invoice'
      @title = params[:location]
      @total_list = Invoice::Ipd.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date,
                                       :created_at.lt => @datepicker_date + 1, is_draft: false, is_deleted: false)
      @maintotalinvoice = @total_list.pluck(:net_amount)
    elsif params[:location] == 'IPD Insurance'
      @title = params[:location].split(' ')[1] + ' Invoice'
      @total_list = Invoice::Insurance.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date,
                                             :created_at.lt => @datepicker_date + 1)
      @maintotalinvoice = @total_list.pluck(:net_amount)
    elsif params[:location] == 'OPD Cash'
      @title = 'Cash Register'
      @total_list = CashRegister.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date,
                                       :created_at.lt => @datepicker_date + 1).not.where(appointment_id: nil)
      @maintotalinvoice = @total_list.pluck(:total)
    elsif params[:location] == 'IPD Cash'
      @title = 'Cash Register'
      @total_list = CashRegister.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date,
                                       :created_at.lt => @datepicker_date + 1).not.where(admission_id: nil)
      @maintotalinvoice = @total_list.pluck(:total)
    elsif params[:location] == 'Pharmacy'
      @title = params[:location] + ' Invoice'
      @total_list = Invoice::Inventories::Department::PharmacyInvoice.where(facility_id: current_facility.id.to_s,
                                                                            :created_at.gte => @datepicker_date,
                                                                            :created_at.lt => @datepicker_date + 1)
      @maintotalinvoice = @total_list.pluck(:total)
    elsif params[:location] == 'Optical'
      @title = params[:location] + ' Invoice'
      @total_list = Invoice::Inventories::Department::OpticalInvoice.where(facility_id: current_facility.id.to_s,
                                                                           :created_at.gte => @datepicker_date,
                                                                           :created_at.lt => @datepicker_date + 1)
      @maintotalinvoice = @total_list.pluck(:total)
    end
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf do
        render template: 'reports/print_invoice_report.pdf.erb', pdf: '', layout: 'pdfgen.html.erb',
               viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true,
               show_as_html: params[:debug].present?, header: { spacing: 4 }, footer: { spacing: 10 },
               orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10,
                                                   right: @print_settings[0]['right_margin'].to_f * 10,
                                                   top: @print_settings[0]['header_height'].to_f,
                                                   bottom: @print_settings[0]['footer_height'].to_f }
      end
    end
    # head :no_content
  end

  def role_wise_invoice
    @is_draft = false
    @bill_by = current_user.try(:fullname)&.titleize
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @facility = current_facility.id
    @organisation = current_user.organisation
    @datepicker_date = if params[:date] == 'Today'
                         Date.current
                       else
                         Date.parse(params[:date])
                       end
    @user_id = current_user.id
    if params[:location] == 'OPD Invoice'
      @title = params[:location]
      @total_list_opd = Invoice::Opd.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date, :created_at.lt => @datepicker_date + 1, user_id: @user_id, is_draft: false, is_deleted: false).includes(:patient, :refund_payments)
      @maintotalinvoice = @total_list_opd.pluck(:net_amount)
    elsif params[:location] == 'IPD Invoice'
      @title = params[:location]
      @total_list_ipd = Invoice::Ipd.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date, :created_at.lt => @datepicker_date + 1, user_id: @user_id, is_draft: false, is_deleted: false).includes(:patient, :refund_payments)
      @maintotalinvoice = @total_list_ipd.pluck(:net_amount)
    end
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf do
        params[:location] = params[:location][0..2]
        render template: 'reports/print_invoice_combined.pdf.erb', pdf: '',
               layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4',
               disable_smart_shrinking: true, show_as_html: params[:debug].present?,
               header: { spacing: 4 }, footer: { spacing: 10 }, orientation: 'Landscape',
               margin: { left: @print_settings[0]['left_margin'].to_f * 10,
                         right: @print_settings[0]['right_margin'].to_f * 10,
                         top: @print_settings[0]['header_height'].to_f,
                         bottom: @print_settings[0]['footer_height'].to_f }
      end
    end
    # head :no_content
  end

  def role_wise_drafts
    @is_draft = true
    @bill_by = current_user.try(:fullname)&.titleize
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @facility = current_facility.id
    @organisation = current_user.organisation
    @datepicker_date = if params[:date] == 'Today'
                         Date.current
                       else
                         Date.parse(params[:date])
                       end
    @user_id = current_user.id
    if params[:location] == 'OPD Invoice'
      @title = params[:location]
      @total_list_opd = Invoice::Opd.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date, :created_at.lt => @datepicker_date + 1, user_id: @user_id, is_draft: true, is_deleted: false).includes(:patient, :refund_payments)
      @maintotalinvoice = @total_list_opd.pluck(:net_amount)
    elsif params[:location] == 'IPD Invoice'
      @title = params[:location]
      @total_list_ipd = Invoice::Ipd.where(facility_id: @facility.to_s, :created_at.gte => @datepicker_date, :created_at.lt => @datepicker_date + 1, user_id: @user_id, is_draft: true, is_deleted: false).includes(:patient, :refund_payments)
      @maintotalinvoice = @total_list_ipd.pluck(:net_amount)
    end
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf do
        params[:location] = params[:location][0..2]
        render template: 'reports/print_invoice_combined.pdf.erb', pdf: '',
               layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4',
               disable_smart_shrinking: true, show_as_html: params[:debug].present?,
               header: { spacing: 4 }, footer: { spacing: 10 }, orientation: 'Landscape',
               margin: { left: @print_settings[0]['left_margin'].to_f * 10,
                         right: @print_settings[0]['right_margin'].to_f * 10,
                         top: @print_settings[0]['header_height'].to_f,
                         bottom: @print_settings[0]['footer_height'].to_f }
      end
    end
    # head :no_content
  end

  def daily_report_all
    @bill_by = 'All Users'
    @is_draft = false
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @facility = current_facility.id
    @organisation = current_user.organisation
    @datepicker_date = Date.parse(params[:date])
    @total_arr = []

    if params[:location] == 'OPD' || params[:location] == 'All'
      @total_list_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date, :created_at.lt => @datepicker_date + 1, is_draft: false, is_deleted: false)
                                          .includes(:refund_payments, :patient)
      @maintotalinvoice_opd = @total_list_opd.pluck(:net_amount)
      @total_list_cash_opd = CashRegister.where(facility_id: current_facility.id.to_s,
                                                :created_at.gte => @datepicker_date,
                                                :created_at.lt => @datepicker_date + 1).not.where(appointment_id: nil)
      @maintotalinvoice_cash_opd = @total_list_cash_opd.pluck(:total)
      @total_arr.push(@maintotalinvoice_cash_opd)
      @total_arr.push(@maintotalinvoice_opd)
    end
    if params[:location] == 'IPD' || params[:location] == 'All'
      @total_list_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date, :created_at.lt => @datepicker_date + 1, is_draft: false, is_deleted: false)
                                    .includes(:patient, :refund_payments)
      @maintotalinvoice_ipd = @total_list_ipd.pluck(:net_amount)
      @total_list_cash_ipd = CashRegister.where(facility_id: current_facility.id.to_s,
                                                :created_at.gte => @datepicker_date,
                                                :created_at.lt => @datepicker_date + 1).not.where(admission_id: nil)
      @maintotalinvoice_cash_ipd = @total_list_cash_ipd.pluck(:total)
      @total_list_insurance = Invoice::Insurance.where(facility_id: current_facility.id.to_s,
                                                       :created_at.gte => @datepicker_date,
                                                       :created_at.lt => @datepicker_date + 1, is_draft: false, is_deleted: false)
      @maintotalinvoice_insurance = @total_list_insurance.pluck(:net_amount)
      @total_arr.push(@maintotalinvoice_insurance)
      @total_arr.push(@maintotalinvoice_ipd)
      @total_arr.push(@maintotalinvoice_cash_ipd)
    end
    if params[:location] == 'All'
      @total_list_pharmacy = Invoice::Inventories::Department::PharmacyInvoice
                             .where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date,
                                    :created_at.lt => @datepicker_date + 1)
      @maintotalinvoice_pharmacy = @total_list_pharmacy.pluck(:total)
      @total_list_optical = Invoice::Inventories::Department::OpticalInvoice
                            .where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date,
                                   :created_at.lt => @datepicker_date + 1)
      @maintotalinvoice_optical = @total_list_optical.pluck(:total)
      @total_arr.push(@maintotalinvoice_optical)
      @total_arr.push(@maintotalinvoice_pharmacy)
    end
    @total_today = @total_arr.compact.sum
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf do
        render template: 'reports/print_invoice_combined.pdf.erb', pdf: '', layout: 'pdfgen.html.erb',
               viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true,
               show_as_html: params[:debug].present?, header: { spacing: 4 }, footer: { spacing: 10 },
               orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10,
                                                   right: @print_settings[0]['right_margin'].to_f * 10,
                                                   top: 0,
                                                   bottom: @print_settings[0]['footer_height'].to_f }
      end
    end
  end

  def daily_report_draft
    @bill_by = 'All Users'
    @is_draft = true
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @facility = current_facility.id
    @organisation = current_user.organisation
    @datepicker_date = Date.parse(params[:date])
    @total_arr = []

    if params[:location] == 'OPD' || params[:location] == 'All'
      @total_list_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date, :created_at.lt => @datepicker_date + 1, is_draft: true, is_deleted: false)
                                          .includes(:refund_payments, :patient)
      @maintotalinvoice_opd = @total_list_opd.pluck(:net_amount)
      @total_list_cash_opd = CashRegister.where(facility_id: current_facility.id.to_s,
                                                :created_at.gte => @datepicker_date,
                                                :created_at.lt => @datepicker_date + 1).not.where(appointment_id: nil)
      @maintotalinvoice_cash_opd = @total_list_cash_opd.pluck(:total)
      @total_arr.push(@maintotalinvoice_cash_opd)
      @total_arr.push(@maintotalinvoice_opd)
    end
    if params[:location] == 'IPD' || params[:location] == 'All'
      @total_list_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date, :created_at.lt => @datepicker_date + 1, is_draft: true, is_deleted: false)
                                    .includes(:patient, :refund_payments)
      @maintotalinvoice_ipd = @total_list_ipd.pluck(:net_amount)
      @total_list_cash_ipd = CashRegister.where(facility_id: current_facility.id.to_s,
                                                :created_at.gte => @datepicker_date,
                                                :created_at.lt => @datepicker_date + 1).not.where(admission_id: nil)
      @maintotalinvoice_cash_ipd = @total_list_cash_ipd.pluck(:total)
      @total_list_insurance = Invoice::Insurance.where(facility_id: current_facility.id.to_s,
                                                       :created_at.gte => @datepicker_date,
                                                       :created_at.lt => @datepicker_date + 1, is_draft: true, is_deleted: false)
      @maintotalinvoice_insurance = @total_list_insurance.pluck(:net_amount)
      @total_arr.push(@maintotalinvoice_insurance)
      @total_arr.push(@maintotalinvoice_ipd)
      @total_arr.push(@maintotalinvoice_cash_ipd)
    end
    if params[:location] == 'All'
      @total_list_pharmacy = Invoice::Inventories::Department::PharmacyInvoice
                             .where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date,
                                    :created_at.lt => @datepicker_date + 1)
      @maintotalinvoice_pharmacy = @total_list_pharmacy.pluck(:total)
      @total_list_optical = Invoice::Inventories::Department::OpticalInvoice
                            .where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date,
                                   :created_at.lt => @datepicker_date + 1)
      @maintotalinvoice_optical = @total_list_optical.pluck(:total)
      @total_arr.push(@maintotalinvoice_optical)
      @total_arr.push(@maintotalinvoice_pharmacy)
    end
    @total_today = @total_arr.compact.sum
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf do
        render template: 'reports/print_invoice_combined.pdf.erb', pdf: '', layout: 'pdfgen.html.erb',
               viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true,
               show_as_html: params[:debug].present?, header: { spacing: 4 }, footer: { spacing: 10 },
               orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10,
                                                   right: @print_settings[0]['right_margin'].to_f * 10,
                                                   top: 0,
                                                   bottom: @print_settings[0]['footer_height'].to_f }
      end
    end
  end

  def daily_report_summary
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @facility = current_facility.id
    @organisation = current_user.organisation
    @datepicker_date = Date.parse(params[:date])
    @total_arr = []

    # OPD"
    @total_list_opd = Invoice::Opd.where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date,
                                         :created_at.lt => @datepicker_date + 1)
    @maintotalinvoice_opd = @total_list_opd.pluck(:net_amount)
    @opd_cash = @total_list_opd.pluck(:cash).flatten.compact.sum
    @opd_card = @total_list_opd.pluck(:card).flatten.compact.sum
    @total_list_cash_opd = CashRegister.where(facility_id: current_facility.id.to_s,
                                              :created_at.gte => @datepicker_date,
                                              :created_at.lt => @datepicker_date + 1).not.where(appointment_id: nil)
    @maintotalinvoice_cash_opd = @total_list_cash_opd.pluck(:total)
    @total_arr.push(@maintotalinvoice_cash_opd)
    @total_arr.push(@maintotalinvoice_opd)
    # IPD
    @total_list_ipd = Invoice::Ipd.where(facility_id: current_facility.id.to_s,
                                         :created_at.gte => @datepicker_date,
                                         :created_at.lt => @datepicker_date + 1)
    @maintotalinvoice_ipd = @total_list_ipd.pluck(:net_amount)
    @ipd_cash = @total_list_ipd.pluck(:cash).flatten.compact.sum
    @ipd_card = @total_list_ipd.pluck(:card).flatten.compact.sum
    @total_list_cash_ipd = CashRegister.where(facility_id: current_facility.id.to_s,
                                              :created_at.gte => @datepicker_date,
                                              :created_at.lt => @datepicker_date + 1).not.where(admission_id: nil)
    @maintotalinvoice_cash_ipd = @total_list_cash_ipd.pluck(:total)
    @total_list_insurance = Invoice::Insurance.where(facility_id: current_facility.id.to_s,
                                                     :created_at.gte => @datepicker_date,
                                                     :created_at.lt => @datepicker_date + 1)
    @maintotalinvoice_insurance = @total_list_insurance.pluck(:net_amount)
    @total_arr.push(@maintotalinvoice_insurance)
    @total_arr.push(@maintotalinvoice_ipd)
    @total_arr.push(@maintotalinvoice_cash_ipd)
    # Inventory
    @total_list_pharmacy = Invoice::Inventories::Department::PharmacyInvoice
                           .where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date,
                                  :created_at.lt => @datepicker_date + 1)
    @maintotalinvoice_pharmacy = @total_list_pharmacy.pluck(:total)
    @total_list_optical = Invoice::Inventories::Department::OpticalInvoice
                          .where(facility_id: current_facility.id.to_s, :created_at.gte => @datepicker_date,
                                 :created_at.lt => @datepicker_date + 1)
    @maintotalinvoice_optical = @total_list_optical.pluck(:total)
    @total_arr.push(@maintotalinvoice_optical)
    @total_arr.push(@maintotalinvoice_pharmacy)
    @total_today = @total_arr.compact.sum
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf do
        render template: 'reports/print_daily_report_summary.pdf.erb', pdf: '', layout: 'pdfgen.html.erb',
               viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true,
               show_as_html: params[:debug].present?, header: { spacing: 4 }, footer: { spacing: 10 },
               margin: { left: @print_settings[0]['left_margin'].to_f * 10,
                         right: @print_settings[0]['right_margin'].to_f * 10,
                         top: @print_settings[0]['header_height'].to_f * 10,
                         bottom: @print_settings[0]['footer_height'].to_f * 10 }
      end
    end
  end

  def collection_stats_mop
    @collection_stats = Finance::StatisticCollectionTransactionData.find_by(id: params[:stats_id])
    @receipt_count = @collection_stats.advance_receipts_count + @collection_stats.bills_count + @collection_stats.refund_advance_count + @collection_stats.refund_bills_count
  end
  # EOF collection_stats_mop

  private

  def get_time_period(time)
    case time
    when 'week'
      7
    when 'month'
      30
    when '3months'
      91
    when '6months'
      182
    when '1year'
      365
    else
      30
    end
  end
end
