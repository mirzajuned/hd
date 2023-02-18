class InvoicesController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def new
    @invoice_type_id = params[:typeid]
    @invoice_type = params[:type]
    @userid = current_user.id
    @invoice = Invoice.new
    if params[:typeid].to_i == 440655000
      @appointmentid = params[:appointmentid]
      @appointment = Appointment.find(@appointmentid)
      @patientid = @appointment.patient.id
      @invoice.appointment_id = @appointmentid
    elsif params[:typeid].to_i == 440654001
      @admissionid = params[:admissionid]
      @admission = Admission.find(@admissionid)
      @patientid = @admission.patient.id
      @invoice.admission_id = @admissionid
    end
    @invoice.patient_id = @patientid
    @invoice.user_id = @userid
    # @patient_details = Patient.find(@patientid)
    # render :text => @invoice.patient.inspect
    @total_invoice_rows = 0
    if (params[:invoice_template] != nil) then
      @template_invoice_details = params[:invoice_template]
      @template_invoice_details = JSON.parse(@template_invoice_details)

      @template_invoice_details.each do |index, template_invoice_detail|
        @total_invoice_rows += 1
        @invoice.invoice_details.build(template_invoice_detail)
      end
    else
      @total_invoice_rows += 1
      1.times { @invoice.invoice_details.build }
    end

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def create
    # render :text => params[:invoice][:patient].inspect
    @invoice = Invoice.new(invoice_params)
    @invoice.save
    @mop = @invoice.mode_of_payment.split(",")
    @mop[0] = @mop[0].capitalize
    if @mop[1].present?
      @mop[1] = @mop[1].capitalize
    end
    @mop = @mop.join(" & ")

    # InvoiceDataWorker.perform_async(@invoice.id.to_s)
    patient = Patient.find(params[:invoice][:patient_id])
    patient.update_attributes(patient_update_params)
    @invoice_details = params[:invoice][:invoice_details_attributes]
    add_non_existing_services(@invoice_details, params[:invoice][:invoice_type], params[:invoice][:invoice_type_id])
    @patient_details = params[:invoice][:patient]

    @invoice_details_obj = @invoice.invoice_details
    @invoice_details_obj.each do |invoice_value|
      if invoice_value["is_advance"] == "Y"
        @advancepayment = AdvancePayment.create!(:amount => ((invoice_value["unit_price"].to_i) * (invoice_value["total_units"].to_i)), :payment_date => Date.current.strftime('%Y-%m-%d'), :is_settled => "N", :is_refunded => "N", :patient_id => patient.id.to_s, :invoice_id => @invoice.id.to_s, :invoice_detail_id => invoice_value.id.to_s, :organisation_id => current_user.organisation_id)
      end
    end

    if params[:invoice].has_key?(:advance_payment_attributes)
      # invoice_adjustment_ids = []
      @invoice_advance_payments = params[:invoice][:advance_payment_attributes]
      @invoice_advance_payments.each do |invoice_key, invoice_value|
        if invoice_value["is_settled"] == "Y"
          @advancepayment_detail = AdvancePayment.find_by(:id => invoice_value["advance_payment_id"])
          if (@advancepayment_detail.try(:id))
            @advancepayment_detail.update(:is_settled => "Y", :settled_date => Date.current.strftime('%Y-%m-%d'))
            advance_payment = @invoice.advance_payment + @advancepayment_detail.amount
            @invoice.update(:advance_payment => advance_payment)
            # @invoice.advance_payment += @advancepayment_detail.amount
            # invoice_adjustment_ids.push(@advancepayment_detail.id.to_s)
            InvoiceJobs::AdvancePaymentJob.perform_later(@advancepayment_detail.id.to_s)
          end
        end
      end
      # @invoice_adjustments = AdvancePayment.where(:id.in => invoice_adjustment_ids)
    end
    respond_to do |format|
      format.js {}
    end
  end

  def edit
    @invoice = Invoice.find_by(id: params[:id])
    respond_to do |format|
      format.js {}
    end
  end

  def update
    # render :text => params

    @invoice = Invoice.find(params[:id])
    patient = Patient.find(params[:invoice][:patient_id])
    patient.update_attributes(patient_update_params)
    @invoice.update(invoice_update_params)
    @mop = @invoice.mode_of_payment.split(",")
    @mop[0] = @mop[0].capitalize
    if @mop[1].present?
      @mop[1] = @mop[1].capitalize
    end
    @mop = @mop.join(" & ")
    @invoice_details = params[:invoice][:invoice_details_attributes]
    add_non_existing_services(@invoice_details, params[:invoice][:invoice_type], params[:invoice][:invoice_type_id])
    @patient_details = params[:invoice][:patient]
    @invoice_details_obj = @invoice.invoice_details
    @invoice_details_obj.each do |invoice_value|
      if invoice_value["is_advance"] == "Y"
        @advancepayment_detail = AdvancePayment.find_by(:invoice_detail_id => invoice_value["id"])
        if (@advancepayment_detail.try(:id))
          @advancepayment_detail.update(:amount => ((invoice_value["unit_price"].to_i) * (invoice_value["total_units"].to_i)))
        else
          @advancepayment = AdvancePayment.create!(:amount => ((invoice_value["unit_price"].to_i) * (invoice_value["total_units"].to_i)), :payment_date => Date.current.strftime('%Y-%m-%d'), :is_settled => "N", :is_refunded => "N", :patient_id => patient.id.to_s, :invoice_id => @invoice.id.to_s, :invoice_detail_id => invoice_value.id.to_s, :organisation_id => current_user.organisation_id)
        end
      elsif invoice_value["is_advance"] == "N"
        @advancepayment_detail = AdvancePayment.find_by(:invoice_detail_id => invoice_value["id"])
        if (@advancepayment_detail.try(:id))
          @advancepayment_detail.delete
        end
      end
    end
    if params[:invoice].has_key?(:advance_payment_attributes)
      # invoice_adjustment_ids = []
      @invoice_advance_payments = params[:invoice][:advance_payment_attributes]
      @invoice_advance_payments.each do |invoice_key, invoice_value|
        if invoice_value["is_settled"] == "Y"
          @advancepayment_detail = AdvancePayment.find_by(:id => invoice_value["advance_payment_id"])
          if (@advancepayment_detail.try(:id))
            @advancepayment_detail.update(:is_settled => "Y", :settled_date => Date.current.strftime('%Y-%m-%d'))
            advance_payment = @invoice.advance_payment + @advancepayment_detail.amount
            @invoice.update(:advance_payment => advance_payment)
            # @invoice.advance_payment += @advancepayment_detail.amount
            # invoice_adjustment_ids.push(@advancepayment_detail.id.to_s)
            InvoiceJobs::AdvancePaymentJob.perform_later(@advancepayment_detail.id.to_s)
          end
        end
      end
      # @invoice_adjustments = AdvancePayment.where(:id.in => invoice_adjustment_ids)
    end
    respond_to do |format|
      format.js {}
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
    @each_day_earnings = Invoice.select("date(created_at) as date, sum(total) as total_earnings")
                                .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                                .group("date(created_at)")
  end

  def service_wise_earnings
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    each_service_earnings_by_day = InvoiceDetail.select("date(created_at) as date, sum(unit_price*total_units) as total_earnings,label")
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

  def print
    @invoice = Invoice.find(params[:invoice_id])
    @mop = @invoice.mode_of_payment.split(",")
    @mop[0] = @mop[0].capitalize
    if @mop[1].present?
      @mop[1] = @mop[1].capitalize
    end
    @mop = @mop.join(" & ")
    # @print_type=params[:print_type]
    @organisation = current_user.organisation
    if params[:admission_id].present? && params[:ipdrecord_id].present?
      @admission = Admission.find_by(:id => params[:admission_id])
      @ipdrecord = IpdRecord.find_by(:id => params[:ipdrecord_id])
    end
    @patient_details = @invoice.patient
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "invoices/printinvoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def print_all
    @invoice = Invoice.find(params[:invoice_id])
    # @mop = @invoice.mode_of_payment.split(",")
    # @mop[0].capitalize
    # if try(@mop[1].present)
    #   @mop[1].capitalize
    # end
    # @mop = @mop.join(" & ")
    @invoice_all = Invoice.where(:admission_id => params[:admission_id], :patient_id => params[:patient_id]).order(:created_at => :desc)
    @organisation = current_user.organisation
    @patient = Patient.find_by(:id => params[:patient_id])
    @patient_details = @invoice.patient
    @admission = Admission.find_by(:id => params[:admission_id])
    @ipdrecord = IpdRecord.find_by(:id => params[:ipdrecord_id])
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "invoices/print_all_invoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  # INVENTORY INVOICES GOES HERE -- added by Kumar Abinash
  def inventory_department_requests_logs
    @log = Inventory::Department::RequestLog.find(params[:log_id])
    # p log
    # log.items.each do |i|
    #   p i
    # end
    @organisation = current_user.organisation
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      # format.pdf { render :template => 'invoices/inventory/request_log.pdf.erb', :pdf => "request_log_#{@log.id}", :layout => 'pdfgen.html.erb', :page_size => 'A4'}
      format.html { render :template => "invoices/inventory/request_log.html.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, },  :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom =>  @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def inventory_checkout_log
    @log = Inventory::CheckoutLog.find(params[:log_id])
    @organisation = current_user.organisation
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      # format.pdf { render :template => 'invoices/inventory/request_log.pdf.erb', :pdf => "request_log_#{@log.id}", :layout => 'pdfgen.html.erb', :page_size => 'A4'}
      format.html { render :template => "invoices/inventory/checkout_log.html.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom =>  @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def inventory_department_checkout_log
    @log = Inventory::Department::CheckoutLog.all[2]
    @organisation = current_user.organisation
    p @organisation
    respond_to do |format|
      # format.pdf { render :template => 'invoices/inventory/request_log.pdf.erb', :pdf => "request_log_#{@log.id}", :layout => 'pdfgen.html.erb', :page_size => 'A4'}
      format.html { render :template => "invoices/inventory/department/checkout_log.html.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @organisation.letter_head_customisations[:left_margin].to_i * 10, right: @organisation.letter_head_customisations[:right_margin].to_i * 10, :top => @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom => @organisation.letter_head_customisations[:footer_height].to_i * 10 } }
    end
  end

  private

  def invoice_params
    params.require(:invoice).permit(:user_id, :appointment_id, :admission_id, :invoice_type_id, :invoice_type, :patient_id, :total, :tax, :additional_discount, :services_discount, :total_discount, :additional_discount_comment, :mode_of_payment, :cash, :card, invoice_details_attributes: [:id, :label, :service_id, :unit_price, :total_units, :is_advance]).merge(:bill_number => CommonHelper::get_invoice_record_identifier(current_user))
  end

  def invoice_update_params
    params.require(:invoice).permit(:user_id, :appointment_id, :admission_id, :invoice_type_id, :invoice_type, :patient_id, :total, :tax, :additional_discount, :services_discount, :total_discount, :additional_discount_comment, :bill_number, :mode_of_payment, :cash, :card, invoice_details_attributes: [:id, :label, :service_id, :unit_price, :total_units, :is_advance])
  end

  def patient_update_params
    params[:invoice].require(:patient).permit(:fullname, :mobilenumber, :age, :gender, :address_1, :address_2, :city, :state, :pincode)
  end

  # internal function for adding services which are not present
  def add_non_existing_services(invoice_details, service_type, service_type_id)
    invoice_details.each do |index, invoice_detail|
      if invoice_detail[:id].nil?
        if !Service.where(name: invoice_detail[:label], organisation_id: current_user.organisation.id).exists?
          @service = Service.new
          @service[:name] = invoice_detail[:label]
          @service[:unit_cost] = invoice_detail[:unit_price]
          @service[:default_units] = invoice_detail[:total_units]
          @service[:organisation_id] = current_user.organisation.id
          @service[:service_type] = service_type
          @service[:service_type_id] = service_type_id
          @service[:is_custom] = "Y"
          @service.save
        end
      end
    end
  end
end
