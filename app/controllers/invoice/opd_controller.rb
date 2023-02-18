class Invoice::OpdController < Invoice::InvoicesController
  before_action :authorize
  respond_to :js, :json, :html
  layout 'loggedin'

  before_action :print_settings, only: [:show, :create, :update, :destroy]

  def new
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @userid = current_user.id
    @invoice = Invoice::Opd.new
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @patientid = @appointment.patient_id
    @patient = Patient.find_by(id: @patientid)
    facility_id = current_facility.id
    @department_id = '485396012'
    @department_name = Department.find_by(id: @department_id).try(:display_name)
    @currency_symbol = (@invoice.currency_symbol || current_facility.currency_symbol)
    @is_draft = (params[:is_draft].present? && params[:is_draft] == 'true') ? true : false
    # CaseSheet
    case_sheet = CaseSheet.find_by(id: @appointment.case_sheet_id)
    @procedures = case_sheet.procedures.map { |procedure| { code: procedure.procedurefullcode, advised_by_id: procedure.advised_by_id, counselled_by_id: procedure.counselled_by_id } }
    @ophthal_investigation = case_sheet.ophthal_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
    @laboratory_investigation = case_sheet.laboratory_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
    @radiology_investigation = case_sheet.radiology_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
    @combined = @procedures + @ophthal_investigation + @laboratory_investigation + @radiology_investigation

    @invoiceservicecard = InvoiceServiceCard.where(facility_id: facility_id, card_deleted: false).not.where(service_type: 'Room')

    @invoice.appointment_id = @appointment.id.to_s
    @facility_id = @appointment.facility_id
    @view_js_erb = '/invoice/opd/new'
    @finance_type = params[:finance_type] if params[:finance_type]
    @service_type = params[:service_type]
    fetch_assessment_data
    super
  end

  def create
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice::Opd.new(opd_invoice_params)
    if @invoice.save(validate: false)
      # generate all the sequences for invoice
      bill_number = SequenceManagers::GenerateSequenceService.call('invoice', @invoice.id.to_s, {organisation_id: current_organisation['_id'].to_s, facility_id: current_facility['_id'].to_s, region_id: current_facility['region_master_id'].to_s, department_id: '485396012'})
      @invoice.update(bill_number: bill_number)

      @invoice.record_histories.create(user_id: current_user.id, action: 'C', actiontime: Time.current, template_type: 'Invoice::Opd')
      @patient = Patient.find_by(id: @invoice.patient_id)
      @appointment = Appointment.find_by(id: @invoice.appointment_id)
      @appointment_list_view = AppointmentListView.find_by(appointment_id: @appointment.id)

      if @invoice.version == 'v21.0'
        @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
        if @facility_setting.present?
          @facility_setting.update(invoice_show_package_breakup: invoice_show_package_breakup(@invoice))
        end
      end
      # to generate for receipt_id for each txn
      Invoice::CreateBillNumberService.call(@invoice)

      create_opd_finance_report

      # Advance Logic
      @invoice.advance_payment_breakups.each do |advance_payment_breakup|
        advance_payment = AdvancePayment.find_by(id: advance_payment_breakup.advance_payment_id)
        next unless advance_payment.present?

        advance_payment.amount_remaining = advance_payment.amount_remaining - advance_payment_breakup.amount
        advance_payment.advance_state = ('Settled' if advance_payment.amount_remaining == 0) || 'None'
        advance_payment.advance_history = advance_payment.try(:advance_history) || []
        advance_history = { advance_payment_breakup_id: advance_payment_breakup.id.to_s, invoice_id: @invoice.id.to_s, invoice_type: 'OPD', type: 'Adjusted', user_name: current_user.fullname, amount: advance_payment_breakup.amount, event_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), bill_number: @invoice.bkp_bill_number }
        advance_payment.advance_history << advance_history

        advance_payment.save
        InvoiceJobs::AdvancePaymentJob.perform_later(advance_payment.id.to_s)
      end

      @adjusted_amount = @invoice.advance_payment

      @invoice.services&.each do |serv|
        OfferManagerJobs::ManageOfferCountJob.perform_later(serv.offer_manager_id.to_s) if serv.offer_manager_id.present?
        service_list = Invoice::ServiceList.find_by(service_name: serv.name, facility_id: @invoice.facility_id)
        if service_list.nil?
          @service_list = Invoice::ServiceList.create(service_name: serv.name, facility_id: @invoice.facility_id, organisation_id: current_user.organisation_id, opdsum: serv.service_total.to_f, use_count_opd: 1)
        else
          service_list.update_attributes(opdsum: (serv.service_total.to_f + service_list.opdsum.to_f), use_count_opd: (service_list.use_count_opd.to_i + 1))
        end
        next unless serv.items

        serv.items.each do |item|
          item_list = Invoice::ItemList.find_by(item_name: item.description, facility_id: @invoice.facility_id)
          if item_list.nil?
            @item_list = Invoice::ItemList.create(item_name: item.description, facility_id: @invoice.facility_id, organisation_id: current_user.organisation_id, opdsum: serv.service_total.to_f, use_count_opd: 1)
          else
            item_list.update_attributes(opdsum: (item.price.to_f + item_list.opdsum.to_f), use_count_opd: (item_list.use_count_opd.to_i + 1))
          end
        end
      end
      # TaxCalculation
      TaxCalculationJob.perform_later(@invoice.id.to_s, 'tax_collected_details') if @invoice.tax_enabled      
      # Create Finance::ReportData data
      unless @invoice.is_draft == true
        InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
        InvoiceJobs::ManageCollectionDataJob.perform_later(@invoice.id.to_s, 'Bill')
        MisJobs::Finance::ItemWiseBillTypeJob.perform_later(@invoice.id.to_s)
        MisJobs::Finance::BillTypeJob.perform_later(@invoice.id.to_s)
        Analytics::Financial::FinancialJob.perform_later(@invoice.id.to_s, 'OPD')
        MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@invoice.id.to_s)
      end
      # EOF Create Finance::ReportData data
      OfferManagerJobs::ManageOfferCountJob.perform_later(@invoice.offer_manager_id.to_s) if @invoice.offer_manager_id.present?

      if @invoice.service_type == "General Consultation"
        if @appointment.present?
          @appointment.update(opd_consultation_taken: true, opd_consultation_amount: @invoice.try(:net_amount),
                              opd_consultation_bill_type: @invoice.try(:invoice_type),
                              opd_consultation_bill_display_id: @invoice.try(:bill_number))
          @appointment_list_view.update(opd_consultation_taken: true, opd_consultation_amount: @invoice.try(:net_amount),
                                        opd_consultation_bill_type: @invoice.try(:invoice_type),
                                        opd_consultation_bill_display_id: @invoice.try(:bill_number))
        end
      end
      fetch_assessment_data
      respond_to do |format|
        format.js { render 'invoice/opd/show' }
      end
      Patients::Summary::TimelineWorker.call(event_name: 'OPD_INVOICE', sub_event_name: 'CREATED', invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: 'OPD', is_draft: @invoice.is_draft)
    end
  end

  def show
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice::Opd.find_by(id: params[:id])
    @adjusted_amount = @invoice.advance_payment
    @patient = Patient.find_by(id: @invoice.patient_id)
    @appointment = Appointment.find_by(id: @invoice.appointment_id)
    @organisation_id = current_user.organisation_id
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    @currency_symbol = (@invoice.currency_symbol || current_facility.currency_symbol)
    @refund_payments = RefundPayment.where(invoice_id: @invoice.id)

    fetch_assessment_data
    respond_to do |format|
      format.js { render 'invoice/opd/show' }
    end
  end

  def edit
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice::Opd.find_by(id: params[:id])
    @department_id = @invoice.department_id || '485396012'
    @department_name = Department.find_by(id: @department_id).try(:display_name)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @appointment = Appointment.find_by(id: @invoice.appointment_id)
    @organisation_id = current_user.organisation_id
    facility_id = @invoice.facility_id
    @currency_symbol = (@invoice.currency_symbol || current_facility.currency_symbol)
    @is_draft = (@invoice.is_draft.present? && @invoice.is_draft == true) ? true : false
    # CaseSheet
    case_sheet = CaseSheet.find_by(id: @appointment.case_sheet_id)
    @procedures = case_sheet.procedures.map { |procedure| { code: procedure.procedurefullcode, advised_by_id: procedure.advised_by_id, counselled_by_id: procedure.counselled_by_id } }
    @ophthal_investigation = case_sheet.ophthal_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
    @laboratory_investigation = case_sheet.laboratory_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
    @radiology_investigation = case_sheet.radiology_investigations.map { |investigation| { code: investigation.investigationfullcode, advised_by_id: investigation.advised_by_id.to_s, counselled_by_id: investigation.counselled_by_id.to_s } }
    @combined = @procedures + @ophthal_investigation + @laboratory_investigation + @radiology_investigation
    @invoiceservicecard = InvoiceServiceCard.where(facility_id: facility_id).not.where(service_type: 'Room')

    @service_type = @invoice.try(:service_type)

    if @service_type == 'General Consultation' && @appointment.present?
      options = { facility_id: facility_id, specialty_id: @invoice.specialty_id, department_id: '485396012', consultant_user_id: @appointment.consultant_id.to_s }
    else
      options = { facility_id: facility_id, specialty_id: @invoice.specialty_id, department_id: '485396012' }
    end
    @pricing_masters = PricingMaster.includes(:service_master, :service_group, :service_sub_group).where(options)
                                    .group_by(&:service_group_id)

    surgery_options = options.merge(activated: true)
    @surgery_packages = SurgeryPackage.where(surgery_options)
    @edit_js_erb = '/invoice/opd/edit'
    fetch_assessment_data
    super
  end

  def update
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice::Opd.find_by(id: params[:id])
    @old_amount = @invoice.net_amount
    @invoice_before = @invoice.net_amount
    @patient = Patient.find_by(id: @invoice.patient_id)
    @appointment = Appointment.find_by(id: @invoice.appointment_id)
    @appointment_list_view = AppointmentListView.find_by(appointment_id: @appointment.id)

    @invoice.services&.each do |serv|
      service_list = Invoice::ServiceList.find_by(service_name: serv.name, facility_id: @invoice.facility_id)
      service_list&.update_attributes(opdsum: (service_list.opdsum.to_f - serv.service_total.to_f), use_count_opd: (service_list.use_count_opd.to_i - 1))
      next unless serv.items

      serv.items.each do |item|
        item_list = Invoice::ItemList.find_by(item_name: item.description, facility_id: @invoice.facility_id)
        item_list&.update_attributes(opdsum: (item_list.opdsum.to_f - item.price.to_f), use_count_opd: (item_list.use_count_opd.to_i - 1))
      end
    end

    # Hack for Repeatative Service Saving
    deleted_services = params[:deleted_services].split(',')
    deleted_services.try(:each) do |ds|
      service = @invoice.services.find_by(id: ds)
      service&.delete
    end

    deleted_items = params[:deleted_items].split(',')
    deleted_items.try(:each) do |di|
      @invoice.services.each do |serv|
        item = serv.items.find_by(id: di)
        item&.delete
      end
    end

    # delete_old_tax_values
    TaxCalculationJob.perform_later(@invoice.id.to_s, 'tax_recollected_details') if @invoice.tax_enabled

    # Find Reports
    find_edit_opd_daily_report

    params[:invoice_opd][:tax_breakup] = [] if params[:invoice_opd][:tax_breakup].nil?

    if @invoice.update_attributes(invoice_update_params)
      # to generate for receipt_id for each txn

      if @invoice.service_type == "General Consultation"
        if @appointment.present?
          @appointment.update(opd_consultation_taken: true, opd_consultation_amount: @invoice.try(:net_amount),
                              opd_consultation_bill_type: @invoice.try(:invoice_type),
                              opd_consultation_bill_display_id: @invoice.try(:bill_number))
          @appointment_list_view.update(opd_consultation_taken: true, opd_consultation_amount: @invoice.try(:net_amount),
                                        opd_consultation_bill_type: @invoice.try(:invoice_type),
                                        opd_consultation_bill_display_id: @invoice.try(:bill_number))
        end
      end

      Invoice::CreateBillNumberService.call(@invoice)

      @invoice.record_histories.create(user_id: current_user.id, action: 'U', actiontime: Time.current, template_type: 'Invoice:Opd')

      @invoice_after = @invoice.net_amount
      @adjusted_amount = @invoice.advance_payment

      # Update Reports
      update_opd_daily_report

      @invoice.services&.each do |serv|
        OfferManagerJobs::ManageOfferCountJob.perform_later(serv.offer_manager_id.to_s) if serv.offer_manager_id.present?
        service_list = Invoice::ServiceList.find_by(service_name: serv.name, facility_id: @invoice.facility_id)
        if service_list.nil?
          @service_list = Invoice::ServiceList.create(service_name: serv.name, facility_id: @invoice.facility_id, organisation_id: current_user.organisation_id, opdsum: serv.service_total.to_f, use_count_opd: 1)
        else
          service_list.update_attributes(opdsum: (serv.service_total.to_f + service_list.opdsum.to_f), use_count_opd: (service_list.use_count_opd.to_i + 1))
        end
        next unless serv.items

        serv.items.each do |item|
          item_list = Invoice::ItemList.find_by(item_name: item.description, facility_id: @invoice.facility_id)
          if item_list.nil?
            @item_list = Invoice::ItemList.create(item_name: item.description, facility_id: @invoice.facility_id, organisation_id: current_user.organisation_id, opdsum: serv.service_total.to_f, use_count_opd: 1)
          else
            item_list.update_attributes(opdsum: (item.price.to_f + item_list.opdsum.to_f), use_count_opd: (item_list.use_count_opd.to_i + 1))
          end
        end
      end

      if @invoice.version == 'v21.0'
        @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
        if @facility_setting.present?
          @facility_setting.update(invoice_show_package_breakup: invoice_show_package_breakup(@invoice))
        end
      end

      # Advance Payment Logic
      @invoice.advance_payment_breakups.each do |advance_payment_breakup|
        advance_payment = AdvancePayment.find_by(id: advance_payment_breakup.advance_payment_id)
        next unless advance_payment.present?

        advance_payment.amount_remaining = advance_payment_breakup.advance_amount - advance_payment_breakup.amount
        advance_payment.advance_state = ('Settled' if advance_payment.amount_remaining == 0) || 'None'
        advance_payment.advance_history = advance_payment.try(:advance_history) || []
        this_advance_history = advance_payment.advance_history.find { |x| x[:advance_payment_breakup_id] == advance_payment_breakup.id.to_s }
        advance_payment.advance_history.delete(this_advance_history) unless this_advance_history.nil?
        advance_history = { advance_payment_breakup_id: advance_payment_breakup.id.to_s, invoice_id: @invoice.id.to_s, invoice_type: 'OPD', type: 'Adjusted', user_name: current_user.fullname, amount: advance_payment_breakup.amount, event_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), bill_number: @invoice.bkp_bill_number }
        advance_payment.advance_history << advance_history

        advance_payment.save
        InvoiceJobs::AdvancePaymentJob.perform_later(advance_payment.id.to_s)
      end

      unless @invoice_after == @invoice_before
        InvoiceLog.create(invoice_date: @invoice.created_at, bkp_bill_number: @invoice.bkp_bill_number, bill_number: @invoice.bill_number, old_total: @invoice_before, new_total: @invoice_after, comment: @invoice.comments, invoice_id: @invoice.id.to_s, user_id: current_user.id, username: current_user.fullname, facility_id: current_facility.id, organisation_id: current_facility.organisation_id, invoice_type: 'OPD')
      end
      # TaxCalculation
      TaxCalculationJob.perform_later(@invoice.id.to_s, 'tax_collected_details') if @invoice.tax_enabled
      Analytics::Financial::FinancialUpdateJob.perform_later(@invoice.id.to_s, 'OPD', @old_amount.to_s)
      # update Finance::ReportData data
      unless @invoice.is_draft == true
        InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
        InvoiceJobs::ManageCollectionDataJob.perform_later(@invoice.id.to_s, 'Bill')
        MisJobs::Finance::ItemWiseBillTypeJob.perform_later(@invoice.id.to_s)
        MisJobs::Finance::BillTypeJob.perform_later(@invoice.id.to_s)
        MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@invoice.id.to_s)
      end
      fetch_assessment_data
      # EOF Create Finance::ReportData data
      respond_to do |format|
        format.js { render 'invoice/opd/show' }
      end
      Patients::Summary::TimelineWorker.call(event_name: 'OPD_INVOICE', sub_event_name: 'UPDATED', invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: 'OPD', is_draft: @invoice.is_draft)
    end
  end

  def destroy
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice::Opd.find_by(id: params[:id])
    @old_amount = @invoice.net_amount
    @patient = Patient.find_by(id: @invoice.patient_id)
    @appointment = Appointment.find_by(id: @invoice.appointment_id)
    @organisation_id = current_user.organisation_id
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    if @invoice.update(is_canceled: true, refund_amount: @invoice.try(:payment_received), is_refunded: true,
                       canceled_by: current_user.try(:fullname), refund_date: Time.current.strftime('%d/%m/%Y'),
                       refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), canceled_by_id: current_user.id,
                       refund_reason: 'Bill Cancelled')

      # @refund_payment = RefundPayment.find_by(invoice_id: @invoice.id)
      @refund_payments = RefundPayment.where(invoice_id: @invoice.id)
      if @refund_payment.present?
        update_opd_refund_payment if @invoice.try(:payment_received).to_f != 0.0
      else
        create_opd_refund_payment if @invoice.try(:payment_received).to_f != 0.0
      end
      respond_to do |format|
        format.js { render 'invoice/opd/show' }
      end
      Patients::Summary::TimelineWorker.call(event_name: 'OPD_INVOICE', sub_event_name: 'CANCELLED', invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: 'OPD')
    end
  end

  def print_full_invoice
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice::Opd.find_by(id: params[:invoice_id])
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id)
    @refund_payments = RefundPayment.where(invoice_id: @invoice.id)
    @organisation = current_user.organisation
    @appointment = Appointment.find_by(id: @invoice.appointment_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'Invoice')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    currency_symbol = (@invoice.currency_symbol || current_facility.currency_symbol)
    fetch_assessment_data
    @locals = { mail_job: false, patient: @patient, appointment: @appointment, invoice: @invoice, refund_payments: @refund_payments, facility_setting: @facility_setting, flag: 'Invoice', invoice_setting: @invoice_setting, organisation_settings: @organisation_settings, currency_symbol: currency_symbol, visit_diagnoses: @visit_diagnoses, visit_ophthal_investigations: @visit_ophthal_investigations, visit_laboratory_investigations: @visit_laboratory_investigations, visit_radiology_investigations: @visit_radiology_investigations, visit_procedures: @visit_procedures }

    @payer_masters = PayerMaster.where(:id.in => (@invoice.payment_received_breakups.pluck(:received_from) + @invoice.payment_pending_breakups.pluck(:received_from)).uniq).map { |c| { id: c.id.to_s, display_name: "#{c.try(:display_name).to_s.titleize} - #{c.contact_group.name.to_s.titleize}" } }

    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      if @invoice.tax_enabled && @invoice_setting.show_tax_in_print
        if params[:page_size] == 'A5'
          format.pdf { render template: 'invoice/opd/print_full_invoice_tax_enabled.pdf.erb', pdf: 'xyz', layout: 'pdfgen_invoice.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: @locals }
        else
          format.pdf { render template: 'invoice/opd/print_full_invoice_tax_enabled.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
        end
      else
        if params[:page_size] == 'A5'
          format.pdf { render template: 'invoice/opd/print_full_invoice_tax_disabled.pdf.erb', pdf: 'xyz', layout: 'pdfgen_invoice.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: @locals }
        else
          format.pdf { render template: 'invoice/opd/print_full_invoice_tax_disabled.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
        end
      end
    end
  end

  private

  def opd_invoice_params
    params.require(:invoice_opd).permit(
      :department_id, :department_name, :specialty_id, :mode_of_payment_insurance, :insurance_display_id, 
      :comments, :user_id, :organisation_id, :facility_id, :net_amount, :total, :version, :invoice_type, 
      :cash, :card, :card_number, :card_transaction_note, :paytm_transaction_id, :paytm_transaction_note, 
      :gpay_transaction_id, :gpay_transaction_note, :phonepe_transaction_id, :phonepe_transaction_note, 
      :transfer_date, :transfer_note, :cheque_date, :cheque_note, :other_transaction_id, :other_note, 
      :tax, :additional_discount, :services_discount, :total_discount, :additional_discount_comment,
      :round, :advance_payment, :amount_remaining, :mode_of_payment, :invoice_payment_type, 
      :contact_group_id, :payer_master_id, :credit_type, :tax_enabled, :non_taxable_amount, 
      :payment_received, :payment_pending, :payment_completed, :amount_paid_tpa, :currency_symbol, 
      :currency_id, :amount_paid_patient, :patient_id, :appointment_id, :tpa_id, :patient_comment, 
      :insurer_group_id, :insurer_id, :is_paid_discounted, :is_free_discounted, :is_paid, :is_free,  
      :is_draft, :converted_to_final_date, :converted_to_final_datetime, :converted_to_final_by,
      :consultant_user_id, :service_type, :corporate_id, :tpa_name, :insurance_name, :insurance_id,
      :corporate_name, :dispensary_id, :dispensary_name,
      :amount_received, :offer_on_bill, :offer_on_services, :total_offer, :offer_manager_id,
      :offer_name, :offer_code, :offer_percentage, :offer_applied_at, :offer_applied_at_name,
      :offer_applied_by, :offer_applied_by_name, :offer_applied_date, :offer_applied_datetime,
      payment_pending_breakup: [:_id, :amount, :received_from, :date, :time],
      payment_received_breakup: [:_id, :amount, :date, :time, :received_by, :received_from, :received_by,
                                 :mode_of_payment, :cash, :card, :card_number, :card_transaction_note,
                                 :paytm_transaction_id, :paytm_transaction_note, :gpay_transaction_id,
                                 :gpay_transaction_note, :phonepe_transaction_id, :phonepe_transaction_note,
                                 :transfer_date, :transfer_note, :cheque_date, :cheque_note, 
                                 :other_transaction_id, :other_note, :receipt_id],
      tax_breakup: [:_id, :amount, :name],
      services: [:_id, :name, :service_total, :payer_master_id, :description, :exception_id, :quantity, 
                  :unit_price, :added_by_id, :advised_by_id, :counselled_by_id, :tax_group_id, 
                  :tax_inclusive, :tax_preference, :non_taxable_amount, :taxable_amount, :price, 
                  :item_code, :patient_payed, :item_entry_date, :entry_type, :sub_specialty_id, 
                  :net_item_price, :discount_amount, :discount_percentage, :discount_reason,
                  :show_breakup_in_print, :offer_manager_id, :offer_name, :offer_code, :offer_percentage,
                  :offer_amount, :offer_applied_at, :offer_applied_at_name, :offer_applied_by,
                  :offer_applied_by_name, :offer_applied_date, :offer_applied_datetime, :service_code,
                  tax_group: [:_id, :amount, :name],
                  items: [:_id, :description, :quantity, :unit_price, :tax_group_id, :tax_inclusive, 
                          :non_taxable_amount, :taxable_amount, :price, :item_code, :patient_payed, 
                          :item_entry_date, tax_group: [:_id, :amount, :name]]],
      advance_payment_breakups_attributes: [:advance_payment_id, :advance_display_id, :reason, 
                  :mode_of_payment, :advance_date, :date, :advance_time, :time, :advance_amount, 
                  :amount, :currency_symbol, :currency_id, :cash, :card, :card_number,
                  :card_transaction_note, :paytm_transaction_id, :paytm_transaction_note,
                  :gpay_transaction_id, :gpay_transaction_note, :phonepe_transaction_id,
                  :phonepe_transaction_note, :transfer_date, :transfer_note, :cheque_date,
                  :cheque_note, :other_transaction_id, :other_note, :user_id],
      payment_received_breakups_attributes: [:amount, :currency_symbol, :currency_id, :date, :time, 
                                             :received_by, :received_from, :mode_of_payment, :cash, :card, 
                                             :card_number, :card_transaction_note, :paytm_transaction_id, 
                                             :paytm_transaction_note, :gpay_transaction_id, 
                                             :gpay_transaction_note, :phonepe_transaction_id,
                                             :phonepe_transaction_note, :transfer_date, :transfer_note, 
                                             :cheque_date, :cheque_note, :other_transaction_id, 
                                             :other_note, :is_settled, :receipt_id, 
                                             :amount_received, :has_tax_deducted, :tax_deducted, 
                                             :has_payer_difference, :payer_difference, 
                                             :has_other_revenue_spilage, :other_revenue_spilage, 
                                             :internal_comment],
      payment_pending_breakups_attributes: [:amount, :currency_symbol, :currency_id, :received_from, :date, :time],
      patient_payer_data_attributes: [:_id, :patient_payer_data_master_id, :name, :text_value, :list_value]
    ).merge(bkp_bill_number: CommonHelper.get_invoice_record_identifier(current_user))
  end

  def invoice_update_params
    params.require(:invoice_opd).permit(
      :department_id, :department_name, :specialty_id, :mode_of_payment_insurance, :insurance_display_id, 
      :comments, :user_id, :organisation_id, :facility_id, :net_amount, :total, :version, :invoice_type, 
      :cash, :card, :card_number, :card_transaction_note, :paytm_transaction_id, :paytm_transaction_note, 
      :gpay_transaction_id, :gpay_transaction_note, :phonepe_transaction_id,
      :phonepe_transaction_note, :transfer_date, :transfer_note, :cheque_date, :cheque_note, 
      :other_transaction_id, :other_note, :tax, :additional_discount, :services_discount, :total_discount, 
      :additional_discount_comment, :round, :advance_payment, :amount_remaining, :mode_of_payment, 
      :invoice_payment_type, :contact_group_id, :payer_master_id, :credit_type, :tax_enabled, 
      :non_taxable_amount, :payment_received, :payment_pending, :payment_completed, :amount_paid_tpa, 
      :currency_symbol, :currency_id, :amount_paid_patient, :patient_id, :appointment_id, :tpa_id, 
      :patient_comment, :is_paid_discounted, :is_free_discounted, :is_paid, :is_free, :is_draft, 
      :converted_to_final_date, :converted_to_final_datetime, :converted_to_final_by, :amount_received, 
      :offer_on_bill, :offer_on_services, :total_offer, :offer_manager_id,
      :offer_name, :offer_code, :offer_percentage, :offer_applied_at, :offer_applied_at_name,
      :offer_applied_by, :offer_applied_by_name, :offer_applied_date, :offer_applied_datetime,
      :consultant_user_id, :service_type, :corporate_id, :tpa_name, :insurance_name, :insurance_id,
      :corporate_name, :dispensary_id, :dispensary_name,
      payment_pending_breakup: [:_id, :amount, :received_from, :date, :time],
      payment_received_breakup: [:_id, :amount, :date, :time, :received_by, :received_from, :received_by,
                                 :mode_of_payment, :cash, :card, :card_number, :card_transaction_note,
                                 :paytm_transaction_id, :paytm_transaction_note, :gpay_transaction_id,
                                 :gpay_transaction_note, :phonepe_transaction_id, :phonepe_transaction_note,
                                 :transfer_date, :transfer_note, :cheque_date, :cheque_note, :other_transaction_id,
                                 :other_note, :receipt_id],
      tax_breakup: [:_id, :amount, :name],
      services: [:_id, :name, :service_total, :payer_master_id, :description, :exception_id, :quantity, 
                  :unit_price, :added_by_id, :advised_by_id, :counselled_by_id, :tax_group_id, 
                  :tax_inclusive, :tax_preference, :non_taxable_amount, :taxable_amount, :price, 
                  :item_code, :patient_payed, :item_entry_date, :entry_type, :sub_specialty_id, 
                  :net_item_price, :discount_amount, :discount_percentage, :discount_reason,
                  :show_breakup_in_print, :offer_manager_id, :offer_name, :offer_code, :offer_percentage,
                  :offer_amount, :offer_applied_at, :offer_applied_at_name, :offer_applied_by,
                  :offer_applied_by_name, :offer_applied_date, :offer_applied_datetime, :service_code,
                  tax_group: [:_id, :amount, :name],
                  items: [:_id, :description, :quantity, :unit_price, :tax_group_id, :tax_inclusive, 
                          :non_taxable_amount, :taxable_amount, :price, :item_code, :patient_payed, 
                          :item_entry_date, tax_group: [:_id, :amount, :name]]],
      advance_payment_breakups_attributes: [:id, :_destroy, :advance_payment_id, :advance_display_id, 
                                            :reason, :mode_of_payment, :advance_date, :date, 
                                            :advance_time, :time, :advance_amount, :amount, 
                                            :currency_symbol, :currency_id, :cash, :card, :card_number,
                                            :card_transaction_note, :paytm_transaction_id, 
                                            :paytm_transaction_note, :gpay_transaction_id, 
                                            :gpay_transaction_note, :phonepe_transaction_id,
                                            :phonepe_transaction_note, :transfer_date, :transfer_note, 
                                            :cheque_date, :cheque_note, :other_transaction_id, :other_note],
      payment_received_breakups_attributes: [:id, :_destroy, :amount, :currency_symbol, :currency_id, 
                                             :date, :time, :received_by, :received_from, :mode_of_payment, 
                                             :cash, :card, :card_number, :card_transaction_note, 
                                             :paytm_transaction_id, :paytm_transaction_note,
                                             :gpay_transaction_id, :gpay_transaction_note, 
                                             :phonepe_transaction_id, :phonepe_transaction_note, 
                                             :transfer_date, :transfer_note, :cheque_date,
                                             :cheque_note, :other_transaction_id, :other_note, 
                                             :is_settled, :receipt_id, :amount_received, 
                                             :has_tax_deducted, :tax_deducted, :has_payer_difference, 
                                             :payer_difference, :has_other_revenue_spilage, 
                                             :other_revenue_spilage, :internal_comment],
      payment_pending_breakups_attributes: [:id, :_destroy, :amount, :currency_symbol, :currency_id, 
                                            :received_from, :date, :time],
      patient_payer_data_attributes: [:_id, :patient_payer_data_master_id, :name, :text_value, :list_value]
    )
  end

  def patient_params
    params.require(:patient).permit(:fullname, :firstname, :middlename, :lastname, :gender, :age, :age_month,
                                    :address_1, :address_2, :city, :state, :pincode, :email)
  end

  def print_settings
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ['485396012'])
  end

  def invoice_show_package_breakup(invoice)
    invoice_surgery_package = invoice.services.where(entry_type: 'surgery_package')
    invoice_surgery_package_show_breakup = invoice_surgery_package.where(show_breakup_in_print: true)
    return (invoice_surgery_package.count == invoice_surgery_package_show_breakup.count)
  end

  def fetch_assessment_data
    case_sheet = CaseSheet.where(patient_id: @patient.id,:appointment_ids.in=> [@appointment.id.to_s])[0]

    if case_sheet.present?
      @visit_diagnoses = case_sheet.diagnoses.where(appointment_id: @appointment.id.to_s)
      @visit_ophthal_investigations = case_sheet.ophthal_investigations.where(appointment_id: @appointment.id.to_s,is_disabled: false)
      @visit_laboratory_investigations = case_sheet.laboratory_investigations.where(appointment_id: @appointment.id.to_s,is_disabled: false)
      @visit_radiology_investigations = case_sheet.radiology_investigations.where(appointment_id: @appointment.id.to_s,is_disabled: false)
    else
      @visit_diagnoses = nil
      @visit_ophthal_investigations = nil
      @visit_laboratory_investigations = nil
      @visit_radiology_investigations = nil
    end
  end
end
