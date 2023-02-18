class Invoice::InsurancesController < ApplicationController
  before_action :authorize

  def new
    @tpa = Inpatient::Insurance::Tpa.find_by(id: params[:tpa_id])
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @organisation_id = current_user.organisation_id
    @organisation = current_user.organisation

    # Logic for INS-INV Display_Id
    @invoicecount = Invoice::Insurance.where(organisation_id: current_user.organisation_id).count
    if @invoicecount < 10
      @displaycounter = @organisation.identifier_prefix + "-INS-INV-00" + (@invoicecount + 1).to_s
    elsif @invoicecount < 100 && @invoicecount > 9
      @displaycounter = @organisation.identifier_prefix + "-INS-INV-0" + (@invoicecount + 1).to_s
    else
      @displaycounter = @organisation.identifier_prefix + "-INS-INV-" + (@invoicecount + 1).to_s
    end
    # Logic for INS-INV Display_Id Ends

    @invoiceservicecard = InvoiceServiceCard.where(facility_id: current_facility.id, card_deleted: false)

    @invoice = Invoice::Insurance.new

    respond_to do |format|
      format.js { render "invoice/insurances/new", layout: false }
    end
  end

  def create
    @invoice = Invoice::Insurance.new(insurance_invoice_params)
    @tpa = Inpatient::Insurance::Tpa.find_by(id: @invoice.tpa_id)
    @patient = Patient.find_by(id: @tpa.patient_id)
    @fullname = (@patient.try(:salutation).to_s + " " + params[:patient][:firstname] + " " + params[:patient][:middlename] + " " + params[:patient][:lastname]).to_s.strip
    puts @fullname

    if @invoice.save(validate: false)
      @patient.update_attributes(patient_params)
      @patient.update_attributes(fullname: @fullname)
      # model method for exact_age
      @patient.get_exact_age(@patient.age.to_i, @patient.age_month.to_i)

      @admission = Admission.find_by(id: @invoice.admission_id)
      # For Refreshing Admission List
      @admission_selected = Admission.find(@tpa.admission_id)

      create_ins_finance_report

      if @invoice.services
        @invoice.services.each do |serv|
          service_list = Invoice::ServiceList.find_by(service_name: serv.name, facility_id: @invoice.facility_id)
          if service_list.nil?
            @service_list = Invoice::ServiceList.create(service_name: serv.name, facility_id: @invoice.facility_id, organisation_id: current_user.organisation_id, insurancesum: serv.service_total.to_f, use_count_insurance: 1)
          else
            service_list.update_attributes(insurancesum: (serv.service_total.to_f + service_list.insurancesum.to_f), use_count_insurance: (service_list.use_count_insurance.to_i + 1))
          end
          if serv.items
            serv.items.each do |item|
              item_list = Invoice::ItemList.find_by(item_name: item.description, facility_id: @invoice.facility_id)
              if item_list.nil?
                @item_list = Invoice::ItemList.create(item_name: item.description, facility_id: @invoice.facility_id, organisation_id: current_user.organisation_id, insurancesum: serv.service_total.to_f, use_count_insurance: 1)
              else
                item_list.update_attributes(insurancesum: (item.price.to_f + item_list.insurancesum.to_f), use_count_insurance: (item_list.use_count_insurance.to_i + 1))
              end
            end
          end
        end
      end

      respond_to do |format|
        format.js { render "invoice/insurances/show", layout: false }
      end
      Patients::Summary::TimelineWorker.call({ event_name: "INSURANCE_INVOICE", sub_event_name: "CREATED", invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: "IPD" })
    end
  end

  def show
    @invoice = Invoice::Insurance.find_by(id: params[:id])
    @tpa = Inpatient::Insurance::Tpa.find_by(id: @invoice.tpa_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @admission = Admission.find_by(id: @invoice.admission_id)
    respond_to do |format|
      format.js { render "invoice/insurances/show", layout: false }
    end
  end

  def edit
    @invoice = Invoice::Insurance.find_by(id: params[:id])
    @tpa = Inpatient::Insurance::Tpa.find_by(id: @invoice.tpa_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @admission = Admission.find_by(id: @invoice.admission_id)
    @organisation_id = current_user.organisation_id
    @invoiceservicecard = InvoiceServiceCard.where(facility_id: current_facility.id)

    respond_to do |format|
      format.js { render "invoice/insurances/edit", layout: false }
    end
  end

  def update
    @invoice = Invoice::Insurance.find_by(id: params[:id])
    @tpa = Inpatient::Insurance::Tpa.find_by(id: @invoice.tpa_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @admission = Admission.find_by(id: @invoice.admission_id)
    @fullname = (@patient.try(:salutation).to_s + " " + params[:patient][:firstname] + " " + params[:patient][:middlename] + " " + params[:patient][:lastname]).to_s.strip
    # puts @fullname

    if @invoice.services
      @invoice.services.each do |serv|
        service_list = Invoice::ServiceList.find_by(service_name: serv.name, facility_id: @invoice.facility_id)
        unless service_list.nil?
          service_list.update_attributes(insurancesum: (service_list.insurancesum.to_f - serv.service_total.to_f), use_count_insurance: (service_list.use_count_insurance.to_i - 1))
        end
        if serv.items
          serv.items.each do |item|
            item_list = Invoice::ItemList.find_by(item_name: item.description, facility_id: @invoice.facility_id)
            unless item_list.nil?
              item_list.update_attributes(insurancesum: (item_list.insurancesum.to_f - item.price.to_f), use_count_insurance: (item_list.use_count_insurance.to_i - 1))
            end
          end
        end
      end
    end

    # Hack for Repeatative Service Saving
    deleted_services = params[:deleted_services].split(",")
    deleted_services.try(:each) do |ds|
      service = @invoice.services.find_by(id: ds)
      service.delete if service
    end

    deleted_items = params[:deleted_items].split(",")
    deleted_items.try(:each) do |di|
      @invoice.services.each do |serv|
        item = serv.items.find_by(id: di)
        item.delete if item
      end
    end

    find_edit_ins_daily_report

    if @invoice.update_attributes(insurance_invoice_params)
      @patient.update_attributes(patient_params)
      @patient.update_attributes(fullname: @fullname)
      # model method for exact_age
      @patient.get_exact_age(@patient.age.to_i, @patient.age_month.to_i)

      update_ins_daily_report

      if @invoice.services
        @invoice.services.each do |serv|
          service_list = Invoice::ServiceList.find_by(service_name: serv.name, facility_id: @invoice.facility_id)
          if service_list.nil?
            @service_list = Invoice::ServiceList.create(service_name: serv.name, facility_id: @invoice.facility_id, organisation_id: current_user.organisation_id, insurancesum: serv.service_total.to_f, use_count_insurance: 1)
          else
            service_list.update_attributes(insurancesum: (serv.service_total.to_f + service_list.insurancesum.to_f), use_count_insurance: (service_list.use_count_insurance.to_i + 1))
          end
          if serv.items
            serv.items.each do |item|
              item_list = Invoice::ItemList.find_by(item_name: item.description, facility_id: @invoice.facility_id)
              if item_list.nil?
                @item_list = Invoice::ItemList.create(item_name: item.description, facility_id: @invoice.facility_id, organisation_id: current_user.organisation_id, insurancesum: serv.service_total.to_f, use_count_insurance: 1)
              else
                item_list.update_attributes(insurancesum: (item.price.to_f + item_list.insurancesum.to_f), use_count_insurance: (item_list.use_count_insurance.to_i + 1))
              end
            end
          end
        end
      end

      # For Refreshing Admission List
      @admission_selected = Admission.find(@tpa.admission_id)
      respond_to do |format|
        format.js { render "invoice/insurances/show", layout: false }
      end
      Patients::Summary::TimelineWorker.call({ event_name: "INSURANCE_INVOICE", sub_event_name: "UPDATED", invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: "IPD" })
    end
  end

  def print_service_invoice
    @invoice = Invoice::Insurance.find_by(id: params[:invoice_id])
    @organisation = current_user.organisation
    @admission = Admission.find_by(id: @invoice.admission_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @tpa = Inpatient::Insurance::Tpa.find_by(id: @invoice.tpa_id)
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "invoice/insurances/print_service_invoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def print_tpa_invoice
    @invoice = Invoice::Insurance.find_by(id: params[:invoice_id])
    @organisation = current_user.organisation
    @admission = Admission.find_by(id: @invoice.admission_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @tpa = Inpatient::Insurance::Tpa.find_by(id: @invoice.tpa_id)
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)

    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "invoice/insurances/print_tpa_invoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_i * 10, right: @print_settings[0]['right_margin'].to_i * 10, :top => @print_settings[0]['header_height'].to_i * 10, :bottom =>  @print_settings[0]['footer_height'].to_i * 10 } }
    end
  end

  def print_patient_invoice
    @invoice = Invoice::Insurance.find_by(id: params[:invoice_id])
    @organisation = current_user.organisation
    @admission = Admission.find_by(id: @invoice.admission_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @tpa = Inpatient::Insurance::Tpa.find_by(id: @invoice.tpa_id)
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "invoice/insurances/print_patient_payable.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_i * 10, right: @print_settings[0]['right_margin'].to_i * 10, :top => @print_settings[0]['header_height'].to_i * 10, :bottom => @print_settings[0]['footer_height'].to_i * 10 } }
    end
  end

  def print_insurance_invoice
    @invoice = Invoice::Insurance.find_by(id: params[:invoice_id])
    @organisation = current_user.organisation
    @admission = Admission.find_by(id: @invoice.admission_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @tpa = Inpatient::Insurance::Tpa.find_by(id: @invoice.tpa_id)
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "invoice/insurances/print_insurance_payable.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def print_full_invoice
    @invoice = Invoice::Insurance.find_by(id: params[:invoice_id])
    @organisation = current_user.organisation
    @admission = Admission.find_by(id: @invoice.admission_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @tpa = Inpatient::Insurance::Tpa.find_by(id: @invoice.tpa_id)
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "invoice/insurances/print_full_invoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_i * 10, right: @print_settings[0]['right_margin'].to_i * 10, :top => @print_settings[0]['header_height'].to_i * 10, :bottom => @print_settings[0]['footer_height'].to_i * 10 } }
    end
  end

  def patient_payed_status
    @invoice = Invoice::Insurance.find_by(:id => params[:invoice_id])
    @item_checked = @invoice.services[(params[:service_count]).to_i].items[(params[:item_count]).to_i]

    patient_payed = params[:flag] == "unchecked" ? "Yes" : "No"

    if @item_checked.update_attributes(patient_payed: patient_payed)
      @total = 0
      @invoice.services.each do |serv|
        serv.items.where(patient_payed: "Yes").each do |ite|
          @total = @total + (ite.price).to_f
        end
      end
      if @invoice.additional_discount?
        @total = @total - @invoice.additional_discount
      end
      render json: { "success": true, "total": @total }
    else
      render json: { "success": false }
    end
  end

  def insurance_payed
    @invoice = Invoice::Insurance.find_by(:id => params[:invoice_id])

    if params[:flag] == "payed"
      @invoice.update_attributes(insurance_payed: true)
    else
      @invoice.update_attributes(insurance_payed: false)
    end

    render json: { "success": true }
  end

  def mopi_patient
    @invoice = Invoice::Insurance.find_by(:id => params[:invoice_id])

    if @invoice.update_attributes(mode_of_payment: params[:mopi])
      render json: { "success": true }
    else
      render json: { "success": false }
    end
  end

  def mopi_insurance
    @invoice = Invoice::Insurance.find_by(:id => params[:invoice_id])

    if @invoice.update_attributes(mode_of_payment_insurance: params[:mopi])
      render json: { "success": true }
    else
      render json: { "success": false }
    end
  end

  private

  def insurance_invoice_params
    params.require(:invoice_insurance).permit(:mode_of_payment_insurance, :comments, :user_id, :insurance_display_id, :organisation_id, :facility_id, :net_amount, :total, :tax, :discount, :advance_payment, :mode_of_payment, :amount_paid_tpa, :amount_paid_patient, :patient_id, :admission_id, :tpa_id, services: [:_id, :name, :service_total, items: [:_id, :item_entry_date, :description, :quantity, :unit_price, :price, :item_code, :patient_payed]])
  end

  def patient_params
    params.require(:patient).permit(:firstname, :middlename, :lastname, :gender, :age, :age_month, :address_1, :address_2, :city, :state, :pincode, :email)
  end

  def create_ins_finance_report
    @ins_cash_report = DailyReport.find_by(date: Date.current, facility_id: @invoice.facility_id, specialty_id: @invoice.specialty_id)
    if @ins_cash_report.nil?
      @ins_cash_report = DailyReport.new
      @ins_cash_report.ins_invoice_ids = [@invoice.id.to_s]
      @ins_cash_report.ins_invoice_transaction = params[:invoice_insurance][:net_amount].to_i
      @ins_cash_report.user_id = current_user.id.to_s
      @ins_cash_report.organisation_id = current_user.organisation_id.to_s
      @ins_cash_report.month = Date.current.month
      @ins_cash_report.year = Date.current.year
      @ins_cash_report.date = Date.current
      @ins_cash_report.facility_id = @invoice.facility_id
      @ins_cash_report.specialty_id = @invoice.specialty_id
      @ins_cash_report.save!
    else
      @ins_cash_today = @ins_cash_report.ins_invoice_transaction
      @invoice_ids = @ins_cash_report.ins_invoice_ids << @invoice.id.to_s
      @ins_cash_report.update_attributes(ins_invoice_transaction: @ins_cash_today.to_i + params[:invoice_insurance][:net_amount].to_i, ins_invoice_ids: @invoice_ids)
    end
  end

  def find_edit_ins_daily_report
    @ins_invoice_report = DailyReport.find_by(:ins_invoice_ids.in => [params[:id]])
    @ins_invoice_money = (@ins_invoice_report.try(:ins_invoice_transaction)).to_i - @invoice.net_amount
  end

  def update_ins_daily_report
    @ins_invoice_money = @ins_invoice_money + @invoice.net_amount
    if @ins_invoice_report
      @ins_invoice_report.update_attributes(ins_invoice_transaction: @ins_invoice_money)
    end
  end
end
