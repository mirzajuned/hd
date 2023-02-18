class Invoice::InvoicesController < ApplicationController
  layout 'loggedin'
  respond_to :js, :json, :html

  attr_accessor :view_js_name, :view_js_erb
  attr_accessor :create_js_name, :create_js_erb
  attr_accessor :edit_js_erb

  before_action :authorize
  before_action :set_payers, only: [:new, :edit, :append_template_set_details]
  before_action :find_invoice, only: [:edit, :update, :payment_received_details, :payed_from_advance_details, :settle_invoice, :save_settled_invoice_details, :print_receipt] #, :show_service_offers
  before_action :invoice_setting, only: [:new, :edit, :show_service_offers]

  def new
    country_id = current_facility.country_id
    facility_id = current_facility.id

    @invoice.patient_id = @patientid
    @invoice.user_id = @userid

    method_type = if params[:type].downcase == 'opd'
                    'tax_enabled_opd'
                  elsif params[:type].downcase == 'ipd'
                    'tax_enabled_ipd'
                  elsif params[:type].downcase == 'optical'
                    'tax_enabled_optical'
                  elsif params[:type].downcase == 'pharmacy'
                    'tax_enabled_pharmacy'
                  end
    if @invoice_setting.send(method_type)
      organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
      @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false).order(created_at: :desc)
    end

    @advance_payments = AdvancePayment.where(patient_id: @patientid, advance_state: 'None', is_deleted: false, is_refunded: false, :department_id.ne => '50121007', :department_id.ne => '284748001')

    @currency = Currency.find_by(id: current_facility.currency_id.to_s)

    @facility_setting = FacilitySetting.find_by(facility_id: facility_id)

    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
    @payer_masters = PayerMaster.includes(:contact_group).where(facility_id: facility_id, is_active: true)

    @total_invoice_rows = 0
    if !params[:invoice_template_id].nil?
      @invoice_template = InvoiceTemplate.find_by(id: params[:invoice_template_id])
      if @invoice_template.present? && @invoice_template.template_details != 'null'
        # @template_services = JSON.parse(@invoice_template.template_details) rescue eval(@invoice_template.template_details)
        @template_services = JSON.parse(@invoice_template.template_details.gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
      end
      if @template_services.count > 0
        @template_services.each_value do |template_service|
          offer_count = offer_counts(@invoice_template.department_id, template_service['entry_type'], template_service['description'])
          template_service.merge!('offer_count' => offer_count)
        end
      end

      options = { facility_id: facility_id, specialty_id: params[:specialty_id], department_id: params[:department_id] }
      @pricing_masters = PricingMaster.includes(:service_master, :service_group, :service_sub_group).where(options).group_by(&:service_group_id)

      surgery_options = options.merge(activated: true)
      @surgery_packages = SurgeryPackage.where(surgery_options)

      payer_master = @payer_masters.find_by(id: @invoice_template.payer_master_id)
      @invoice.invoice_type = @invoice_template.payer_master_id == 'general' ? 'cash' : 'credit'
      @invoice.contact_group_id = payer_master&.contact_group_id
      @invoice.payer_master_id = @invoice_template.payer_master_id
      @service_total = @invoice_template.total

      if params[:type] == 'OPD'
        respond_to do |format|
          format.html {}
          format.js   { render '/invoice/opd/new_template', layout: false }
        end
      else
        respond_to do |format|
          format.html {}
          format.js   { render '/invoice/ipd/new_template', layout: false }
        end
      end
    else
      @total_invoice_rows += 1
      1.times { @invoice.services.build }

      respond_to do |format|
        format.html {}
        format.js   { render @view_js_erb, layout: false }
      end
    end
  end

  def create
    if @invoice_type == :opd_invoice
      @invoice = Invoice::Opd.new(invoice_params)
    elsif @invoice_type == :ipd_invoice
      @invoice = Invoice::Ipd.new(invoice_params)
    end
    @invoice.save

    # opd invoice report ends here
    @mop = @invoice.mode_of_payment.split(',')
    @mop[0] = @mop[0].capitalize
    @mop[1] = @mop[1].capitalize if @mop[1].present?
    @mop = @mop.join(' & ')

    # InvoiceDataWorker.perform_async(@invoice.id.to_s)
    patient = Patient.find_by(id: params[:invoice][:patient_id])
    patient.update_attributes(patient_update_params)
    # model method for exact_age
    patient.get_exact_age(patient.age.to_i, patient.age_month.to_i)

    @services = params[:invoice][:services_attributes]
    add_non_existing_services(@services, params[:invoice][:invoice_type], params[:invoice][:invoice_type_id])
    @patient_details = params[:invoice][:patient]

    @services_obj = @invoice.services
    @services_obj.each do |invoice_value|
      if invoice_value['is_advance'] == 'Y'
        @advancepayment = AdvancePayment.create!(amount: (invoice_value['unit_price'].to_i * invoice_value['total_units'].to_i), payment_date: Date.current.strftime('%Y-%m-%d'), is_settled: 'N', is_refunded: 'N', patient_id: patient.id.to_s, invoice_id: @invoice.id.to_s, service_id: invoice_value.id.to_s, organisation_id: current_user.organisation_id)
      end
    end

    if params[:invoice].key?(:advance_payment_attributes)
      # invoice_adjustment_ids = []
      @invoice_advance_payments = params[:invoice][:advance_payment_attributes]
      @invoice_advance_payments.each do |_invoice_key, invoice_value|
        next unless invoice_value['is_settled'] == 'Y'

        @advancepayment_detail = AdvancePayment.find_by(id: invoice_value['advance_payment_id'])
        next unless @advancepayment_detail.try(:id)

        @advancepayment_detail.update(is_settled: 'Y', settled_date: Date.current.strftime('%Y-%m-%d'))
        advance_payment = @invoice.advance_payment + @advancepayment_detail.amount
        @invoice.update(advance_payment: advance_payment)
        # @invoice.advance_payment += @advancepayment_detail.amount
        # invoice_adjustment_ids.push(@advancepayment_detail.id.to_s)
        InvoiceJobs::AdvancePaymentJob.perform_later(@advancepayment_detail.id.to_s)
      end
      # @invoice_adjustments = AdvancePayment.where(:id.in => invoice_adjustment_ids)
    end

    respond_to do |format|
      format.html {}
      format.js { render @create_js_erb, layout: false }
    end
  end

  def edit
    @tax_groups = TaxGroup.where(:organisation_id.in => [current_user.organisation_id, $HG_ORGANISATION_ID]).order(created_at: :desc)
    # @invoice = Invoice.find_by(id: params[:id])
    @payer_masters = PayerMaster.includes(:contact_group).where(facility_id: current_facility.id, is_active: true)

    @advance_payments = AdvancePayment.where(patient_id: @invoice.patient_id, '$or' => [{ advance_state: 'None' }, { :id.in => @invoice.advance_payment_breakups.pluck(:advance_payment_id) }], is_deleted: false, is_refunded: false)

    @currency = Currency.find_by(id: current_facility.currency_id.to_s)

    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)

    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
    @payer_masters = PayerMaster.includes(:contact_group).where(facility_id: current_facility.id, is_active: true)


    @payer_master_id = @invoice.payer_master_id.to_s
    @invoice_type = @invoice.department_name.to_s.downcase
    payer_master = PayerMaster.find_by(id: @payer_master_id)
    if payer_master.present?
      patient_payer_data_ids = payer_master.patient_payer_data_details.to_s
      patient_payer_data_id_array = (patient_payer_data_ids.split(",") + @invoice.patient_payer_data.pluck(:patient_payer_data_master_id)).uniq
    end
    if patient_payer_data_id_array.present?
      @patient_payer_data_master = Finance::PatientPayerDataMaster.where(:id.in => patient_payer_data_id_array)
    end

    respond_to do |format|
      format.js { render @edit_js_erb, layout: false }
    end
  end

  def update
    # render :text => params

    # @invoice = Invoice.find_by(id: params[:id])
    patient = Patient.find_by(id: params[:invoice][:patient_id])
    patient.update_attributes(patient_update_params)

    # model method for exact_age
    patient.get_exact_age(patient.age.to_i, patient.age_month.to_i)
    @invoice.update(invoice_update_params)

    @mop = @invoice.mode_of_payment.split(',')
    @mop[0] = @mop[0].capitalize
    @mop[1] = @mop[1].capitalize if @mop[1].present?
    @mop = @mop.join(' & ')
    @services = params[:invoice][:services_attributes]
    add_non_existing_services(@services, params[:invoice][:invoice_type], params[:invoice][:invoice_type_id])
    patient_details = params[:invoice][:patient]
    @services_obj = @invoice.services
    @services_obj.each do |invoice_value|
      if invoice_value['is_advance'] == 'Y'
        @advancepayment_detail = AdvancePayment.find_by(service_id: invoice_value['id'])
        if @advancepayment_detail.try(:id)
          @advancepayment_detail.update(amount: (invoice_value['unit_price'].to_i * invoice_value['total_units'].to_i))
        else
          @advancepayment = AdvancePayment.create!(amount: (invoice_value['unit_price'].to_i * invoice_value['total_units'].to_i), payment_date: Date.current.strftime('%Y-%m-%d'), is_settled: 'N', is_refunded: 'N', patient_id: patient.id.to_s, invoice_id: @invoice.id.to_s, service_id: invoice_value.id.to_s, organisation_id: current_user.organisation_id)
        end
      elsif invoice_value['is_advance'] == 'N'
        @advancepayment_detail = AdvancePayment.find_by(service_id: invoice_value['id'])
        @advancepayment_detail.delete if @advancepayment_detail.try(:id)
      end
    end
    if params[:invoice].key?(:advance_payment_attributes)
      # invoice_adjustment_ids = []
      @invoice_advance_payments = params[:invoice][:advance_payment_attributes]
      @invoice_advance_payments.each do |_invoice_key, invoice_value|
        next unless invoice_value['is_settled'] == 'Y'

        @advancepayment_detail = AdvancePayment.find_by(id: invoice_value['advance_payment_id'])
        next unless @advancepayment_detail.try(:id)

        @advancepayment_detail.update(is_settled: 'Y', settled_date: Date.current.strftime('%Y-%m-%d'))
        advance_payment = @invoice.advance_payment + @advancepayment_detail.amount
        @invoice.update(advance_payment: advance_payment)
        InvoiceJobs::AdvancePaymentJob.perform_later(@advancepayment_detail.id.to_s)
      end
    end

    if params[:invoice_services_for_delete] != ''
      @invoice.services.where(:id.in => params[:invoice_services_for_delete].split(',')).delete
    end

    respond_to do |format|
      format.html {}
      format.js { render @update_js_erb, layout: false }
    end
  end


  def append_template_set_details
    set_id = params[:set_id].to_s

    @invoice_type = params[:invoice_type]
    @department_id= params[:department_id]
    @specialty_id = params[:specialty_id]
    @patient_id = params[:patient_id]

    @invoice_template = InvoiceTemplate.find_by(id: set_id)

    if @invoice_template.present? && @invoice_template.template_details != 'null'
      # @template_services = JSON.parse(@invoice_template.template_details) rescue eval(@invoice_template.template_details)
      @template_services = JSON.parse(@invoice_template.template_details.gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
    end

    if @invoice_type == 'opd'
      @appointment = Appointment.find_by(id: params[:appointment_id])
      @facility = Facility.find_by(id: @appointment.try(:facility_id))
      @doctor = @appointment.try(:doctor)
      @case_sheet_id = @appointment.try(:case_sheet_id)
    elsif @invoice_type == 'ipd'
      @admission = Admission.find_by(id: params[:admission_id])
      @facility = Facility.find_by(id: @admission.try(:facility_id))
      @doctor = @admission.try(:doctor)
      @case_sheet_id = @admission.try(:case_sheet_id)
    else
      @facility = current_facility
    end


    @invoice = Invoice.find_by(id: params[:invoice_id])

    if @invoice.blank?
      if @invoice_type == 'opd'
        @invoice = Invoice::Opd.new(id: params[:invoice_id], department_id: @department_id, specialty_id: @specialty_id, patient_id: @patient_id)
      elsif @invoice_type == 'ipd'
        @invoice = Invoice::Ipd.new(id: params[:invoice_id], department_id: @department_id, specialty_id: @specialty_id, patient_id: @patient_id)
      else
        @invoice = Invoice.new(id: params[:invoice_id], department_id: @department_id, specialty_id: @specialty_id, patient_id: @patient_id)
      end
    end

    @currency_symbol = (@invoice.try(:currency_symbol) || @facility.currency_symbol)

    @currency = Currency.find_by(id: @facility.currency_id.to_s)

    options = { facility_id: @facility.id, specialty_id: params[:specialty_id], department_id: params[:department_id] }
    @pricing_masters = PricingMaster.includes(:service_master, :service_group, :service_sub_group).where(options).group_by(&:service_group_id)

    surgery_options = options.merge(activated: true)
    @surgery_packages = SurgeryPackage.where(surgery_options)


    # CaseSheet
    case_sheet_id = @appointment.try(:case_sheet_id)

    case_sheet = (CaseSheet.find_by(id: case_sheet_id) if case_sheet_id) || nil
    if case_sheet.present?
      @procedures = case_sheet.procedures.map { |procedure| { code: procedure.procedurefullcode, advised_by_id: procedure.advised_by_id, counselled_by_id: procedure.counselled_by_id } }
      @ophthal_investigation = case_sheet.ophthal_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
      @laboratory_investigation = case_sheet.laboratory_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
      @radiology_investigation = case_sheet.radiology_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
      @combined = @procedures + @ophthal_investigation + @laboratory_investigation + @radiology_investigation
    else
      @combined = []
    end


  end

  def template_set_details
    payer_master_id = params[:payer_master_id].to_s

    if payer_master_id.blank?
      payer_master_id = 'general'
    end

    @invoice_type = params[:invoice_type]
    @department_id= params[:department_id]
    @specialty_id = params[:specialty_id]
    @appointment_id = params[:appointment_id]
    @admission_id = params[:admission_id]
    @invoice_id = params[:invoice_id]
    @patient_id = params[:patient_id]

    @invoice_templates = InvoiceTemplate.where(payer_master_id: payer_master_id, department_id: @department_id,
                                               facility_id: current_facility.id, specialty_id: @specialty_id,
                                               is_active: true, version: "v21.0")
  end

  def update_patient_payer_data_form
    payer_master_id = params[:payer_master_id].to_s

    @invoice_type = params[:invoice_type]
    payer_master = PayerMaster.find_by(id: payer_master_id)
    if payer_master.present?
      patient_payer_data_ids = payer_master.patient_payer_data_details.to_s
    end

    if patient_payer_data_ids.present?
      @patient_payer_data_master = Finance::PatientPayerDataMaster.where(:id.in => patient_payer_data_ids.split(","), is_disable: false)

      if @patient_payer_data_master.blank?
        respond_to do |format|
          format.js { render nothing: true }
        end
      end
    end
  end

  def set_invoice_pricing_masters # invoice
    payer_master_id = params[:payer_master_id].presence
    @entry_type = params[:entry_type]
    @service_type = params[:service_type]
    @appointment_id = params[:appointment_id]
    facility_id = params[:facility_id] || current_facility.id.to_s

    @appointment = Appointment.find_by(id: @appointment_id)


    if @service_type == 'General Consultation' && @appointment.present?
      query_options = { specialty_id: params[:specialty_id], facility_id: facility_id,
                        department_id: params[:department_id], consultant_user_id: @appointment.consultant_id.to_s, is_active: true }
    else
      query_options = { specialty_id: params[:specialty_id], facility_id: facility_id,
                        department_id: params[:department_id], payer_master_id: payer_master_id, is_active: true }
    end


    if @entry_type == 'service'
      # CaseSheet
      case_sheet = (CaseSheet.find_by(id: params[:case_sheet_id]) if params[:case_sheet_id]) || nil
      if case_sheet.present?
        @procedures = case_sheet.procedures.map { |procedure| { code: procedure.procedurefullcode, advised_by_id: procedure.advised_by_id, counselled_by_id: procedure.counselled_by_id } }
        @ophthal_investigation = case_sheet.ophthal_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
        @laboratory_investigation = case_sheet.laboratory_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
        @radiology_investigation = case_sheet.radiology_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
        @combined = @procedures + @ophthal_investigation + @laboratory_investigation + @radiology_investigation
      else
        @combined = []
      end

      # PricingMaster
      @pricing_masters = PricingMaster.includes(:service_master, :service_group, :service_sub_group)
                                      .where(query_options).group_by(&:service_sub_group_id)
    elsif @entry_type == 'surgery_package'
      query_options = query_options.merge(activated: true)

      # SurgeryPackage
      @surgery_packages = SurgeryPackage.where(query_options)
    elsif @entry_type == 'bill_of_material'
      @bill_of_materials = Inpatient::BillOfMaterial.where(patient_id: params[:patient_id], is_billed: false, is_canceled: false)
    end
    respond_to do |format|
      format.html { render 'set_invoice_pricing_masters.html.erb', layout: false }
    end
  end

  def billing_report
    respond_to do |format|
      format.js {}
    end
  end

  def day_wise_earnings
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    @each_day_earnings = Invoice.select('date(created_at) as date, sum(total) as total_earnings')
                                .where(created_at: start_date.beginning_of_day..end_date.end_of_day,
                                        is_draft: false, is_deleted: false)
                                .group('date(created_at)')
  end

  def service_wise_earnings
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    each_service_earnings_by_day = InvoiceDetail.select('date(created_at) as date, sum(unit_price*total_units) as total_earnings,label')
                                                .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                                                .group('date(created_at),label')
    @each_service_earnings = {}
    each_service_earnings_by_day.each do |single_earning|
      unless @each_service_earnings[single_earning[:label]].present?
        @each_service_earnings[single_earning[:label]] = {}
        # @each_service_earnings[single_earning[:label]]["each_day_details"] = {}
      end
      @each_service_earnings[single_earning[:label]][single_earning[:date]] = single_earning[:total_earnings]
      # logger.debug("adsfdsaf"+single_earning[:label])
    end
  end

  def print_flags
    @invoice = Invoice.find_by(id: params[:invoice_id])
    @invoice.update_attributes("#{params[:flag_name]}": params[:flag])
    render json: { "success": true }
  end

  def print
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice.find_by(id: params[:invoice_id])
    @mop = if @invoice.mode_of_payment == 'cash,card'
             'Cash & Card'
           else
             @invoice.mode_of_payment.capitalize
           end
    @organisation = current_user.organisation
    if params[:admission_id].present? && params[:ipdrecord_id].present?
      @admission = Admission.find_by(id: params[:admission_id])
      @ipdrecord = IpdRecord.find_by(id: params[:ipdrecord_id])
    end
    @patient_details = @invoice.patient
    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, 'Invoice')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    if params[:pagesize] == 'A4'
      respond_to do |format|
        format.pdf { render template: 'invoices/printinvoice.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
      end
    elsif params[:pagesize] == 'A5'
      respond_to do |format|
        format.pdf { render template: 'invoices/printinvoice_a5.pdf.erb', pdf: 'xyz', layout: 'pdfgen_invoice.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' } }
      end
    end
  end

  def print_all
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice.find_by(id: params[:invoice_id])
    @invoice_all = Invoice.where(admission_id: params[:admission_id], patient_id: params[:patient_id], is_deleted: false).order(created_at: :desc)
    @organisation = current_user.organisation
    @patient = Patient.find_by(id: params[:patient_id])
    @patient_details = @invoice.patient
    @admission = Admission.find_by(id: params[:admission_id])
    @ipdrecord = IpdRecord.find_by(id: params[:ipdrecord_id])
    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, 'Invoice')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'invoices/print_all_invoice.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def service_name_list
    @servicelist = Invoice::ServiceList.where(service_name: /#{Regexp.escape(params[:q])}/i, facility_id: params[:facility_id])
    respond_to do |format|
      format.json { render 'invoice/service_name_list', layout: false }
    end
  end

  def item_name_list
    @itemlist = Invoice::ItemList.where(item_name: /#{Regexp.escape(params[:q])}/i, facility_id: params[:facility_id])
    respond_to do |format|
      format.json { render 'invoice/item_name_list', layout: false }
    end
  end

  def invoice_log
    @invoicelogs = InvoiceLog.where(invoice_id: params[:invoice_id]).order(created_at: :desc)
    respond_to do |format|
      format.js { render 'invoice_log/invoice_log.js.erb', layout: false }
    end
  end

  def payment_received_details
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    # @invoice = Invoice.find_by(id: params[:id])
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ['485396012'])
  end

  def payed_from_advance_details
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    # @invoice = Invoice.find_by(id: params[:id])
  end

  def settle_invoice
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    # @invoice = Invoice.find_by(id: params[:id])
    @payer_masters = PayerMaster.includes(:contact_group).where(facility_id: current_facility.id, is_active: true)
  end

  def settle_invoices
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
    #settle_invoices_filter
    @invoice_type = params[:type]
    @is_draft = params[:is_draft] || false
  end

  def settle_invoices_filter
    @data_array, @summary = Invoice::PendingBillService.call(params, current_facility, current_organisation, current_user)
  end

  def tax_breakup
    if params[:tax_group_id].present?
      @tax_group = TaxGroup.find_by(id: params[:tax_group_id])
      @tax = []
      @tax_group.tax_rate_details.each do |tax_rate_detail|
        tax_rate = TaxRate.find tax_rate_detail[:_id]
        tax_rate_amount = if @tax_group.rate.to_f != 0.0
                            ((params[:taxable_amount].to_f * tax_rate_detail[:rate].to_f) / @tax_group.rate.to_f)
                          else
                            0.0
                          end
        @tax.push([tax_rate_detail[:_id], tax_rate_detail[:name], tax_rate_amount.round(2), tax_rate_detail[:rate], tax_rate.type])
      end
    else
      @tax = []
    end
    render json: { "tax": @tax }
  end

  def save_settled_invoice_details
    # @invoice = Invoice.find_by(id: params[:id])
    @patient = Patient.find_by(id: @invoice.patient_id)
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
    @invoice_type = @invoice._type
    @type = @invoice_type.split('::')[1].to_s&.underscore&.downcase
    @store_id = params[:store_id]
    find_edit_opd_daily_report if @type == 'opd'
    find_edit_ipd_daily_report if @type == 'ipd'

    @invoice.payment_pending = params[:settle_invoice][:payment_pending].to_f
    @invoice.payment_received = @invoice.payment_received + params[:settle_invoice][:payment_received].to_f
    
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)

    invoice_payment_pending = 0
    department_ids = @invoice._type == 'Invoice::Opd' ? ['485396012'] : ['486546481']
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, department_ids)
    invoice_amount_received = 0
    currency_id = (@invoice.currency_id || current_facility.currency_id)
    currency_symbol = (@invoice.currency_symbol || current_facility.currency_symbol)
    params[:settle_invoice][:payment_received_breakups].to_unsafe_h.each do |_k, payment_received|
      # next unless payment_received[:settle_amount].to_f > 0
      total_amount_received = payment_received[:amount_received].to_f + payment_received[:tax_deducted].to_f + payment_received[:payer_difference].to_f + payment_received[:other_revenue_spilage].to_f
      next unless total_amount_received > 0

      invoice_amount_received = invoice_amount_received + payment_received[:amount_received].to_f

      payment_pending_breakup = @invoice.payment_pending_breakups.find_by(id: payment_received[:payment_pending_id])
      next unless payment_pending_breakup.present?

      # Payment Received Document
      payment_received_breakups_new = @invoice.payment_received_breakups.new
      # payment_received_breakups_new[:amount] = payment_received[:settle_amount]
      payment_received_breakups_new[:amount] = total_amount_received.round(2)
      payment_received_breakups_new[:date] = payment_received[:date]
      payment_received_breakups_new[:time] = payment_received[:time]
      payment_received_breakups_new[:received_by] = payment_received[:received_by]
      payment_received_breakups_new[:received_from] = payment_received[:received_from]
      payment_received_breakups_new[:mode_of_payment] = payment_received[:mode_of_payment]
      payment_received_breakups_new[:cash] = payment_received[:cash]
      payment_received_breakups_new[:card] = payment_received[:card]
      payment_received_breakups_new[:card_number] = payment_received[:card_number]
      payment_received_breakups_new[:card_transaction_note] = payment_received[:card_transaction_note]
      payment_received_breakups_new[:paytm_transaction_id] = payment_received[:paytm_transaction_id]
      payment_received_breakups_new[:paytm_transaction_note] = payment_received[:paytm_transaction_note]
      payment_received_breakups_new[:gpay_transaction_id] = payment_received[:gpay_transaction_id]
      payment_received_breakups_new[:gpay_transaction_note] = payment_received[:gpay_transaction_note]
      payment_received_breakups_new[:phonepe_transaction_id] = payment_received[:phonepe_transaction_id]
      payment_received_breakups_new[:phonepe_transaction_note] = payment_received[:phonepe_transaction_note]
      payment_received_breakups_new[:transfer_date] = payment_received[:transfer_date]
      payment_received_breakups_new[:transfer_note] = payment_received[:transfer_note]
      payment_received_breakups_new[:cheque_date] = payment_received[:cheque_date]
      payment_received_breakups_new[:cheque_note] = payment_received[:cheque_note]
      payment_received_breakups_new[:other_transaction_id] = payment_received[:other_transaction_id]
      payment_received_breakups_new[:other_note] = payment_received[:other_note]
      payment_received_breakups_new[:is_settled] = payment_received[:is_settled]
      payment_received_breakups_new[:amount_received] = payment_received[:amount_received].to_f.round(2)
      payment_received_breakups_new[:has_tax_deducted] = payment_received[:has_tax_deducted]
      payment_received_breakups_new[:tax_deducted] = payment_received[:tax_deducted].to_f.round(2)
      payment_received_breakups_new[:has_payer_difference] = payment_received[:has_payer_difference]
      payment_received_breakups_new[:payer_difference] = payment_received[:payer_difference].to_f.round(2)
      payment_received_breakups_new[:has_other_revenue_spilage] = payment_received[:has_other_revenue_spilage]
      payment_received_breakups_new[:other_revenue_spilage] = payment_received[:other_revenue_spilage].to_f.round(2)
      payment_received_breakups_new[:internal_comment] = payment_received[:internal_comment]
      payment_received_breakups_new[:currency_id] = currency_symbol
      payment_received_breakups_new[:currency_symbol] = currency_symbol
      # to generate for receipt_id for each txn
      Invoice::CreateBillNumberService.call(@invoice)
      payment_received_breakups_new.save!
      # Payment Pending Document
      if total_amount_received != payment_received[:amount].to_f
        amount_remaining = (payment_received[:amount].to_f - total_amount_received).round(2)
        payment_pending_breakup.update(amount: amount_remaining, date: Date.current, time: Time.current.utc)
        invoice_payment_pending = invoice_payment_pending + amount_remaining
      elsif total_amount_received == payment_received[:amount].to_f
        payment_pending_breakup.delete
      end
    end
    @invoice.amount_received = (@invoice.amount_received.to_f + invoice_amount_received).round(2)
    # @invoice.payment_pending = invoice_payment_pending.round(2)
    
    if @invoice.save
      update_opd_daily_report if @type == 'opd'
      update_ipd_daily_report if @type == 'ipd'
      @refund_payments = RefundPayment.where(invoice_id: @invoice.id)

      @invoices = if @invoice_type.present?
                    Invoice.where(facility_id: current_facility.id.to_s, payment_completed: false, _type: @invoice_type, is_deleted: false)
                  else
                    Invoice.where(facility_id: current_facility.id.to_s, payment_completed: false, is_deleted: false)
                  end

      if @type.to_s.upcase == "OPD"
        fetch_opd_assessment_data
      elsif @type.to_s.upcase == "IPD"
        fetch_ipd_assessment_data
      end

      InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
      InvoiceJobs::ManageCollectionDataJob.perform_later(@invoice.id.to_s, 'Bill')
      MisJobs::Finance::ItemWiseBillTypeJob.perform_later(@invoice.id.to_s)
      MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@invoice.id.to_s)
    end
    @is_draft = false
  end

  def print_receipt
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    # @invoice = Invoice.find_by(id: params[:id])
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id)
    @appointment = Appointment.find_by(id: @invoice.appointment_id)
    @admission = Admission.find_by(id: @invoice.admission_id)
    @payment_received = @invoice.payment_received_breakups.find_by(id: params[:payment_received_id])
    @refund_payments = RefundPayment.where(invoice_id: @invoice.id)
    @receiving_user = User.find_by(id: @payment_received.received_by)
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    if @payment_received.received_from.to_s == @invoice.patient_id.to_s
      @received_from = @invoice.patient.fullname
    else
      @payer_master = PayerMaster.find_by(id: @payment_received.received_from.to_s)
      @received_from = @payer_master.try(:display_name).to_s.titleize + ' - ' + @payer_master.contact_group.name.to_s.titleize
    end
    @patient = Patient.find_by(id: @invoice.patient_id)
    @organisation = current_user.organisation
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'Invoice')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    currency_symbol = (@invoice.currency_symbol || current_facility.currency_symbol)
    @locals = { mail_job: false, patient: @patient, appointment: @appointment, invoice: @invoice, refund_payment: @refund_payment, facility_setting: @facility_setting, flag: 'Invoice', invoice_setting: @invoice_setting, organisation_settings: @organisation_settings, currency_symbol: currency_symbol }
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      #format.pdf { render template: 'invoice/invoices/print_receipt.pdf.erb', pdf: 'xyz', layout: 'pdfgen_invoice.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, , show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }}

      format.pdf { render template: 'invoice/invoices/print_receipt.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
  end

  def set_pricing_exceptions
    @pricing_master = PricingMaster.find_by(id: params[:pricing_master_id])
  end

  def convert_to_final
    invoice_type = params[:type]
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice.find_by(id: params[:invoice_id])
    @appointment = Appointment.find_by(id: @invoice.appointment_id) if params[:type] == 'OPD'
    @admission = Admission.find_by(id: @invoice.admission_id) if params[:type] == 'IPD'
    @invoice.update(is_draft: false, converted_to_final_date: Date.current, converted_to_final_datetime: Time.current, converted_to_final_by: params[:user_id])
    @adjusted_amount = @invoice.advance_payment
    @patient = Patient.find_by(id: @invoice.patient_id)
    @organisation_id = current_user.organisation_id
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    @currency_symbol = (@invoice.currency_symbol || current_facility.currency_symbol)
    @refund_payment = RefundPayment.find_by(invoice_id: @invoice.id)
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, [@invoice.department_id])
    InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
    InvoiceJobs::ManageCollectionDataJob.perform_later(@invoice.id.to_s, 'Bill')
    MisJobs::Finance::ItemWiseBillTypeJob.perform_later(@invoice.id.to_s)
    MisJobs::Finance::BillTypeJob.perform_later(@invoice.id.to_s)
    Analytics::Financial::FinancialJob.perform_later(@invoice.id.to_s, invoice_type.upcase)
    MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@invoice.id.to_s)

    if invoice_type.to_s.upcase == "OPD"
      fetch_opd_assessment_data
    elsif invoice_type.to_s.upcase == "IPD"
      fetch_ipd_assessment_data
    end

    if invoice_type == 'OPD' || invoice_type == 'opd'
      Patients::Summary::TimelineWorker.call(event_name: 'OPD_INVOICE', sub_event_name: 'UPDATED', invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: 'OPD', is_converted: @invoice.is_draft)
      respond_to do |format|
        format.js { render 'invoice/opd/show' }
      end
    else
      Patients::Summary::TimelineWorker.call(event_name: 'IPD_INVOICE', sub_event_name: 'UPDATED', invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: 'IPD', is_converted: @invoice.is_draft)
      respond_to do |format|
        format.js { render 'invoice/ipd/show' }
      end
    end
  end

  def delete_draft
    invoice_type = params[:type]
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice.find_by(id: params[:invoice_id])
    @appointment = Appointment.find_by(id: @invoice.appointment_id) if params[:type] == 'OPD'
    @admission = Admission.find_by(id: @invoice.admission_id) if params[:type] == 'IPD'
    # invoice -> BOMs
    bom_ids = @invoice.services.where(entry_type: 'bill_of_material').pluck(:description).flatten
    Inpatient::BillOfMaterial.where(:id.in => bom_ids).update_all(is_billed: false)
    # end invoice -> BOMs
    @invoice.update(is_deleted: true, deleted_date: Date.current, deleted_datetime: Time.current, deleted_by: params[:user_id])
    @adjusted_amount = @invoice.advance_payment
    @patient = Patient.find_by(id: @invoice.patient_id)
    @organisation_id = current_user.organisation_id
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    @currency_symbol = (@invoice.currency_symbol || current_facility.currency_symbol)
    @refund_payment = RefundPayment.find_by(invoice_id: @invoice.id)
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, [@invoice.department_id])
    if invoice_type == 'OPD' || invoice_type == 'opd'
      # Patients::Summary::TimelineWorker.call(event_name: 'OPD_INVOICE', sub_event_name: 'UPDATED', invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: 'OPD', is_deleted: @invoice.is_deleted)
      respond_to do |format|
        format.js { render 'invoice/opd/show' }
      end
    else
      # Patients::Summary::TimelineWorker.call(event_name: 'IPD_INVOICE', sub_event_name: 'UPDATED', invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: 'IPD', is_deleted: @invoice.is_deleted)
      respond_to do |format|
        format.js { render 'invoice/ipd/show' }
      end
    end
  end

  def show_service_offers
    @service_id = params[:service_id]
    @row_count = params[:row_count]
    @invoice_department_type = params[:invoice_department_type]
    @action = params[:invoice_action]
    # @invoice = Invoice.find_by(id: params[:invoice_id])
    appointment_id = params[:appointment_id]
    @appointment = Appointment.find_by(id: appointment_id)
    @selected_offer_id = params[:selected_offer_id]
    @offer_managers = OfferManager.where(:start_datetime.lte => Time.current, :end_datetime.gte => Time.current, facility_id: current_facility.id, organisation_id: current_organisation['_id'], offer_type: 'service', service_id: BSON::ObjectId(@service_id.to_s), is_active: true).order(end_datetime: :asc)
  end

  def show_bill_offers
    @service_id = nil
    @store_id = params[:store_id]
    @department_id = params[:department_id]
    @invoice_department_type = params[:invoice_department_type]
    @action = params[:invoice_action]
    if @store_id.present?
      @offer_managers = OfferManager.where(:start_datetime.lte => Time.current, :end_datetime.gte => Time.current, facility_id: current_facility.id, organisation_id: current_organisation['_id'], department_id: @department_id.to_s, store_id: @store_id, offer_type: 'bill', is_active: true).order(end_datetime: :asc)
    else
      @offer_managers = OfferManager.where(:start_datetime.lte => Time.current, :end_datetime.gte => Time.current, facility_id: current_facility.id, organisation_id: current_organisation['_id'], department_id: @department_id.to_s, offer_type: 'bill', is_active: true).order(end_datetime: :asc)
    end
  end

  def get_offer_count
    type = params[:type]
    department_id = params[:department_id]
    store_id = params[:store_id]
    offer_managers_count = 0
    if type == 'service'
      service_id = params[:service_id]
      offer_managers_count = offer_counts(department_id, type, service_id)
    else
      if store_id.present?
        offer_managers_count = offer_counts(department_id, type, '', store_id)
      else
        offer_managers_count = offer_counts(department_id, type)
      end
    end
    render json: {count: offer_managers_count}.to_json
  end

  private

  def department_details(type)
    department_id =
      if type == 'OPD' #485396012
        '485396012'
      elsif type == 'IPD' #486546481
        '486546481'
      end
    department_name = department_id ? Department.find_by(id: department_id).try(:display_name) : nil
    [department_id, department_name]
  end

  def get_invoice_class_name
    @class_name = @instance_variable.class
  end

  def get_invoice_controller_name
    @controller_name = @instance_variable.class.to_s.split('::').join('_').pluralize.downcase
  end

  def get_invoice_variable
    @instance_variable = instance_variable_get("@#{controller_name.singularize}")
  end

  def mode_of_payment
    @mop = @instance_variable.mode_of_payment.split(',')
    @mop[0] = @mop[0].capitalize
    @mop[1] = @mop[1].capitalize if @mop[1].present?
    @mop = @mop.join(' & ')
  end

  def invoice_params
    params.require(:invoice).permit(:user_id, :appointment_id, :admission_id, :invoice_type_id, :invoice_type, :patient_id, :total, :tax, :discount, :mode_of_payment, :cash, :card, services_attributes: [:id, :label, :service_id, :unit_price, :total_units, :is_advance, :name, :service_type]).merge(bkp_bill_number: CommonHelper.get_invoice_record_identifier(current_user))
    # , bill_number: CommonHelper::get_record_sequences(current_organisation['_id'].to_s, current_facility['_id'].to_s, 'invoice', {department_id: department_details(params['type']).try(:first), region: current_facility['state']})
    
  end

  def invoice_update_params
    params.require(:invoice).permit(:user_id, :appointment_id, :admission_id, :invoice_type_id, :invoice_type, :patient_id, :total, :tax, :discount, :bkp_bill_number, :bill_number, :mode_of_payment, :cash, :card, services_attributes: [:id, :label, :service_id, :unit_price, :total_units, :is_advance, :name, :service_type])
  end

  def patient_update_params
    params[:invoice].require(:patient).permit(:fullname, :mobilenumber, :age, :age_month, :gender, :address_1, :address_2, :city, :state, :pincode)
  end

  # internal function for adding services which are not present
  def add_non_existing_services(services, service_type, service_type_id)
    services.each do |_index, service|
      next unless service[:id].nil?

      next if Service.where(name: service[:label], organisation_id: current_user.organisation.id).exists?

      @service = Service.new
      @service[:name] = service[:label]
      @service[:unit_cost] = service[:unit_price]
      @service[:default_units] = service[:total_units]
      @service[:organisation_id] = current_user.organisation.id
      @service[:service_type] = service_type
      @service[:service_type_id] = service_type_id
      @service[:is_custom] = 'Y'
      @service.save
    end
  end

  def create_opd_finance_report
    @opd_cash_report = DailyReport.find_by(date: Date.current, facility_id: @invoice.facility_id, specialty_id: @invoice.specialty_id, currency_id: @invoice.currency_id)
    # if params[:invoice_opd][:payment_received_breakup] != ""
    #   @payment_received = params[:invoice_opd][:payment_received_breakup].inject(0){|m,x| m += x[:amount].to_f}
    # else
    #   @payment_received = 0
    # end
    @payment_received = params[:invoice_opd][:payment_received].to_f

    @total_tax = if params[:invoice_opd][:tax_breakup].present? && params[:invoice_opd][:tax_breakup] != ''
                   params[:invoice_opd][:tax_breakup].inject(0) { |amount, x| amount += x[:amount].to_f }
                 else
                   0
                 end

    if @opd_cash_report.nil?
      @opd_cash_report = DailyReport.new
      @opd_cash_report.opd_invoice_ids = [@invoice.id.to_s]
      @opd_cash_report.opd_invoice_transaction = if params[:invoice_opd][:mode_of_payment] == 'Cash'
                                                   params[:invoice_opd][:cash].to_i
                                                 elsif params[:invoice_opd][:mode_of_payment] == 'Card'
                                                   params[:invoice_opd][:card].to_i
                                                 else
                                                   params[:invoice_opd][:net_amount].to_i
                                                 end
      @opd_cash_report.opd_invoice_payment_received = @payment_received
      @opd_cash_report.opd_tax_collected = @total_tax
      @opd_cash_report.opd_invoice_payment_pending = params[:invoice_opd][:payment_pending].to_f
      @opd_cash_report.user_id = params[:invoice_opd][:user_id]
      @opd_cash_report.organisation_id = User.find_by(id: params[:invoice_opd][:user_id]).try(:organisation_id)
      @opd_cash_report.month = Date.current.month
      @opd_cash_report.year = Date.current.year
      @opd_cash_report.date = Date.current
      @opd_cash_report.facility_id = @invoice.facility_id
      @opd_cash_report.specialty_id = @invoice.specialty_id
      @opd_cash_report.currency_id = @invoice.currency_id
      @opd_cash_report.currency_symbol = @invoice.currency_symbol
      @opd_cash_report.save!
    else
      @opd_cash_today = @opd_cash_report.opd_invoice_transaction
      @invoice_ids = @opd_cash_report.opd_invoice_ids << @invoice.id.to_s
      @opd_cash_report.update_attributes(opd_invoice_payment_received: @opd_cash_report.opd_invoice_payment_received.to_f + @payment_received, opd_invoice_payment_pending: @opd_cash_report.opd_invoice_payment_pending.to_f + params[:invoice_opd][:payment_pending].to_f, opd_tax_collected: @opd_cash_report.opd_tax_collected.to_f + @total_tax)
      if params[:invoice_opd][:mode_of_payment] == 'Cash'
        @opd_cash_report.update_attributes(opd_invoice_transaction: @opd_cash_today.to_i + params[:invoice_opd][:cash].to_i, opd_invoice_ids:  @invoice_ids)

      elsif params[:invoice_opd][:mode_of_payment] == 'Card'
        @opd_cash_report.update_attributes(opd_invoice_transaction: @opd_cash_today.to_i + params[:invoice_opd][:card].to_i, opd_invoice_ids:  @invoice_ids)
      else
        @opd_cash_report.update_attributes(opd_invoice_transaction: @opd_cash_today.to_i + params[:invoice_opd][:net_amount].to_i)
      end
    end
  end

  def create_ipd_finance_report
    @ipd_cash_report = DailyReport.find_by(date: Date.current, facility_id: @invoice.facility_id, specialty_id: @invoice.specialty_id, currency_id: @invoice.currency_id)

    # if params[:invoice_ipd][:payment_received_breakup] != ""
    #   @payment_received = params[:invoice_ipd][:payment_received_breakup].inject(0){|m,x| m += x[:amount].to_f}
    # else
    #   @payment_received = 0
    # end
    @payment_received = params[:invoice_ipd][:payment_received].to_f

    @total_tax = if params[:invoice_ipd][:tax_breakup].present? && params[:invoice_ipd][:tax_breakup] != ''
                   params[:invoice_ipd][:tax_breakup].inject(0) { |amount, x| amount += x[:amount].to_f }
                 else
                   0
                 end

    if @ipd_cash_report.nil?
      @ipd_cash_report = DailyReport.new
      @ipd_cash_report.ipd_invoice_ids = [@invoice.id.to_s]
      @ipd_cash_report.ipd_invoice_transaction = if params[:invoice_ipd][:mode_of_payment] == 'Cash'
                                                   params[:invoice_ipd][:cash].to_i.to_i
                                                 elsif params[:invoice_ipd][:mode_of_payment] == 'Card'
                                                   params[:invoice_ipd][:cash].to_i.to_i
                                                 else
                                                   params[:invoice_ipd][:net_amount].to_i
                                                 end
      @ipd_cash_report.ipd_invoice_payment_received = @payment_received
      @ipd_cash_report.ipd_tax_collected = @total_tax
      @ipd_cash_report.ipd_invoice_payment_pending = params[:invoice_ipd][:payment_pending].to_f
      @ipd_cash_report.user_id = current_user.id.to_s
      @ipd_cash_report.organisation_id = current_user.organisation_id.to_s
      @ipd_cash_report.month = Date.current.month
      @ipd_cash_report.year = Date.current.year
      @ipd_cash_report.date = Date.current
      @ipd_cash_report.facility_id = @invoice.facility_id
      @ipd_cash_report.specialty_id = @invoice.specialty_id
      @ipd_cash_report.currency_id = @invoice.currency_id
      @ipd_cash_report.currency_symbol = @invoice.currency_symbol
      @ipd_cash_report.save!
    else
      @ipd_cash_today = @ipd_cash_report.ipd_invoice_transaction
      @invoice_ids = @ipd_cash_report.ipd_invoice_ids << @invoice.id.to_s
      @ipd_cash_report.update_attributes(ipd_invoice_payment_received: @ipd_cash_report.ipd_invoice_payment_received + @payment_received, ipd_invoice_payment_pending: @ipd_cash_report.ipd_invoice_payment_pending.to_f + params[:invoice_ipd][:payment_pending].to_f, ipd_tax_collected: @ipd_cash_report.ipd_tax_collected.to_f + @total_tax)
      if params[:invoice_ipd][:mode_of_payment] == 'Cash'
        @ipd_cash_report.update_attributes(ipd_invoice_transaction: @ipd_cash_today.to_i + params[:invoice_ipd][:cash].to_i.to_i, ipd_invoice_ids:  @invoice_ids)

      elsif params[:invoice_ipd][:mode_of_payment] == 'Card'
        @ipd_cash_report.update_attributes(ipd_invoice_transaction: @ipd_cash_today.to_i + params[:invoice_ipd][:card].to_i.to_i, ipd_invoice_ids:  @invoice_ids)
      else
        @ipd_cash_report.update_attributes(ipd_invoice_transaction: @ipd_cash_today.to_i + params[:invoice_ipd][:net_amount].to_i, ipd_invoice_ids: @invoice_ids)
      end
    end
  end

  def create_opd_refund_payment
    @department_id, @department_name = department_details('OPD')
    @refund_payment = RefundPayment.new
    @refund_payment.refund_display_id = CommonHelper.get_refund_identifier(current_user)
    @refund_payment.type = 'OPD'
    @refund_payment.department_id = @department_id
    @refund_payment.department_name = @department_name
    @refund_payment.currency_symbol = '₹'
    @refund_payment.currency_id = 'INR001'
    @refund_payment.patient_id = @invoice.patient_id
    @refund_payment.user_id = current_user.id
    @refund_payment.facility_id = @invoice.facility_id
    @refund_payment.organisation_id = @invoice.organisation_id
    @refund_payment.invoice_id = @invoice.id
    @refund_payment.payment_time = Time.current.strftime('%I:%M %p, %d/%m/%Y')
    @refund_payment.payment_date = Time.current.strftime('%d/%m/%Y')
    @refund_payment.reason = 'Cancellation'
    @refund_payment.specialty_id = @invoice.specialty_id
    @refund_payment.mode_of_payment = 'Cash'
    @refund_payment.cash = @invoice.try(:payment_received).to_f
    @refund_payment.amount = @invoice.try(:payment_received).to_f
    if @refund_payment.save!
      InvoiceJobs::ManageCollectionDataJob.perform_later(@refund_payment.id.to_s, 'Refund')
      InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
      InvoiceJobs::CancelReturnInvoiceJob.perform_later(@refund_payment.id.to_s, 'return', 'receipt')
    end
  end

  def update_opd_refund_payment
    @refund_payment = RefundPayment.find_by(invoice_id: @invoice.id)
    if @refund_payment.present?
      @refund_payment.user_id = current_user.id
      @refund_payment.payment_time = Time.current.strftime('%I:%M %p, %d/%m/%Y')
      @refund_payment.payment_date = Time.current.strftime('%d/%m/%Y')
      @refund_payment.reason = 'Cancellation'
      @refund_payment.cash = @invoice.try(:payment_received).to_f
      @refund_payment.amount = @invoice.try(:payment_received).to_f
      if @refund_payment.save!
        InvoiceJobs::ManageCollectionDataJob.perform_later(@refund_payment.id.to_s, 'Refund')
        InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
        InvoiceJobs::CancelReturnInvoiceJob.perform_later(@refund_payment.id.to_s, 'return', 'receipt')
      end
    end
  end

  def create_ipd_refund_payment
    @department_id, @department_name = department_details('OPD')
    @refund_payment = RefundPayment.new
    @refund_payment.refund_display_id = CommonHelper.get_refund_identifier(current_user)
    @refund_payment.type = 'IPD'
    @refund_payment.department_id = @department_id
    @refund_payment.department_name = @department_name
    @refund_payment.currency_symbol = '₹'
    @refund_payment.currency_id = 'INR001'
    @refund_payment.patient_id = @invoice.patient_id
    @refund_payment.user_id = current_user.id
    @refund_payment.facility_id = @invoice.facility_id
    @refund_payment.organisation_id = @invoice.organisation_id
    @refund_payment.invoice_id = @invoice.id
    @refund_payment.payment_time = Time.current.strftime('%I:%M %p, %d/%m/%Y')
    @refund_payment.payment_date = Time.current.strftime('%d/%m/%Y')
    @refund_payment.reason = 'Cancellation'
    @refund_payment.specialty_id = @invoice.specialty_id
    @refund_payment.mode_of_payment = 'Cash'
    @refund_payment.cash = @invoice.try(:payment_received).to_f
    @refund_payment.amount = @invoice.try(:payment_received).to_f
    if @refund_payment.save!
      InvoiceJobs::ManageCollectionDataJob.perform_later(@refund_payment.id.to_s, 'Refund')
      InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
      InvoiceJobs::CancelReturnInvoiceJob.perform_later(@refund_payment.id.to_s, 'return', 'receipt')
    end
  end

  def update_ipd_refund_payment
    @refund_payment = RefundPayment.find_by(invoice_id: @invoice.id)
    if @refund_payment.present?
      @refund_payment.user_id = current_user.id
      @refund_payment.payment_time = Time.current.strftime('%I:%M %p, %d/%m/%Y')
      @refund_payment.payment_date = Time.current.strftime('%d/%m/%Y')
      @refund_payment.reason = 'Cancellation'
      @refund_payment.cash = @invoice.try(:payment_received).to_f
      @refund_payment.amount = @invoice.try(:payment_received).to_f
      if @refund_payment.save!
        InvoiceJobs::ManageCollectionDataJob.perform_later(@refund_payment.id.to_s, 'Refund')
        InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
        InvoiceJobs::CancelReturnInvoiceJob.perform_later(@refund_payment.id.to_s, 'return', 'receipt')
      end
    end
  end

  def find_edit_opd_daily_report
    @opd_invoice_report = DailyReport.find_by(:opd_invoice_ids.in => [params[:id]])
    @opd_invoice_money = @opd_invoice_report.try(:opd_invoice_transaction).to_f - @invoice.net_amount.to_f
    @opd_invoice_payment_received = @opd_invoice_report.try(:opd_invoice_payment_received).to_f - @invoice.payment_received.to_f
    @opd_invoice_payment_pending = @opd_invoice_report.try(:opd_invoice_payment_pending).to_f - @invoice.payment_pending.to_f
    @opd_tax_collected = @opd_invoice_report.try(:opd_tax_collected) - @invoice.tax_breakup.inject(0) { |amount, x| amount += x[:amount].to_f }
  end

  def find_edit_ipd_daily_report
    @ipd_invoice_report = DailyReport.find_by(:ipd_invoice_ids.in => [params[:id]])
    @ipd_invoice_money = @ipd_invoice_report.try(:ipd_invoice_transaction).to_f - @invoice.net_amount.to_f
    @ipd_invoice_payment_received = @ipd_invoice_report.try(:ipd_invoice_payment_received).to_f - @invoice.payment_received.to_f
    @ipd_invoice_payment_pending = @ipd_invoice_report.try(:ipd_invoice_payment_pending).to_f - @invoice.payment_pending.to_f
    @ipd_tax_collected = @ipd_invoice_report.try(:ipd_tax_collected) - @invoice.tax_breakup.inject(0) { |amount, x| amount += x[:amount].to_f }
  end

  def update_opd_daily_report
    @opd_invoice_money += @invoice.net_amount
    @opd_invoice_payment_received += @invoice.payment_received.to_f
    @opd_invoice_payment_pending += @invoice.payment_pending.to_f
    @opd_tax_collected += @invoice.tax_breakup.inject(0) { |amount, x| amount += x[:amount].to_f }
    @opd_invoice_report.update_attributes(opd_invoice_transaction: @opd_invoice_money, opd_invoice_payment_received: @opd_invoice_payment_received, opd_invoice_payment_pending: @opd_invoice_payment_pending, opd_tax_collected: @opd_tax_collected)
  end

  def update_ipd_daily_report
    @ipd_invoice_money += @invoice.net_amount
    @ipd_invoice_payment_received += @invoice.payment_received.to_f
    @ipd_invoice_payment_pending += @invoice.payment_pending.to_f
    @ipd_tax_collected += @invoice.tax_breakup.inject(0) { |amount, x| amount += x[:amount].to_f }
    @ipd_invoice_report.update_attributes(ipd_invoice_transaction: @ipd_invoice_money, ipd_invoice_payment_received: @ipd_invoice_payment_received, ipd_invoice_payment_pending: @ipd_invoice_payment_pending, ipd_tax_collected: @ipd_tax_collected)
  end

  def invoice_setting
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
  end

  def set_payers
    contact_groups = ContactGroup.where(name: 'Insurance').pluck(:id).map(&:to_s)
    @payer_masters = PayerMaster.where(facility_id: current_facility.id.to_s)

    @payer_fields = @payer_masters.map { |c| { id: c.id.to_s, display_name: c.display_name, contact_group_id: c.contact_group_id.to_s } }
    @insurance_payer_fields = @payer_fields.select { |c| c if contact_groups.include?(c[:contact_group_id]) }
  end

  def find_invoice
    @invoice = Invoice.find_by(id: params[:id])
  end

  def offer_counts(department_id, type, service_id='', store_id='')
    if type == 'service'
      OfferManager.where(:start_datetime.lte => Time.current, :end_datetime.gte => Time.current, facility_id: current_facility.id, organisation_id: current_organisation['_id'], department_id: department_id, offer_type: type, service_id: service_id, is_active: true).count
    elsif type == 'bill' && store_id.present?
      OfferManager.where(:start_datetime.lte => Time.current, :end_datetime.gte => Time.current, facility_id: current_facility.id, organisation_id: current_organisation['_id'], department_id: department_id, store_id: store_id, offer_type: type, is_active: true).count
    elsif type == 'bill'
      OfferManager.where(:start_datetime.lte => Time.current, :end_datetime.gte => Time.current, facility_id: current_facility.id, organisation_id: current_organisation['_id'], department_id: department_id, offer_type: type, is_active: true).count
    else
      0
    end
  end

  def fetch_opd_assessment_data
    case_sheet = CaseSheet.where(patient_id: @patient.id,:appointment_ids.in=> [@invoice.appointment_id.to_s])[0]

    if case_sheet.present?
      @visit_diagnoses = case_sheet.diagnoses.where(appointment_id: @invoice.appointment_id.to_s)
      @visit_ophthal_investigations = case_sheet.ophthal_investigations.where(appointment_id: @invoice.appointment_id.to_s,is_disabled: false)
      @visit_laboratory_investigations = case_sheet.laboratory_investigations.where(appointment_id: @invoice.appointment_id.to_s,is_disabled: false)
      @visit_radiology_investigations = case_sheet.radiology_investigations.where(appointment_id: @invoice.appointment_id.to_s,is_disabled: false)
    else
      @visit_diagnoses = nil
      @visit_ophthal_investigations = nil
      @visit_laboratory_investigations = nil
      @visit_radiology_investigations = nil
    end
  end


  def fetch_ipd_assessment_data
    @ipd_record = Inpatient::IpdRecord.where(admission_id: @invoice.admission_id.to_s)[0]

    @visit_diagnoses = @ipd_record.try(:diagnosislist)

    @visit_procedures = @ipd_record.procedure.where(is_performed: true)

    # @visit_ophthal_investigations = @ipd_record.ophthal_investigations_list.where(is_disabled: false)
    # @visit_laboratory_investigations = @ipd_record.laboratory_investigations_list.where(is_disabled: false)
    # @visit_radiology_investigations = @ipd_record.radiology_investigations_list.where(is_disabled: false)
    @visit_ophthal_investigations = nil
    @visit_laboratory_investigations = nil
    @visit_radiology_investigations = nil
  end
end
