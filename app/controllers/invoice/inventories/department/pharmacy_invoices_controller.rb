class Invoice::Inventories::Department::PharmacyInvoicesController < ApplicationController
  before_action :authorize
  before_action :set_invoice_inventory_department_pharmacy, only: [:show, :edit, :update, :destroy]
  include ActionView::Helpers::NumberHelper
  include Invoice::Inventories::Department::PharmacyHelper
  include MedicineCountHelper

  def index
    facility_id = current_facility.id
    @invoice_inventory_department_pharmacies = Invoice::Inventories::Department::PharmacyInvoice.where(facility_id: facility_id).ordered_first.limit(10)
    # @invoice_inventory_department_pharmacies = Invoice::Inventories::Department::PharmacyInvoice.all
    # render json: @invoice_inventory_department_pharmacies.as_json
  end

  def show_more_checkout_log
    @count = params[:count]
    facility_id = current_facility.id
    @invoice_inventory_department_pharmacies = Invoice::Inventories::Department::PharmacyInvoice.where(facility_id: facility_id).ordered_first.skip(params[:count].to_i).limit(10)
    respond_to do |format|
      format.js {}
    end
  end

  # GET /invoice/inventory/department/pharmacies/new
  def new
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)
    patient_id = params[:patient_id]

    # @patient_prescription = PatientPrescription.find(params[:prescription_id])
    @patient = Patient.find(patient_id)
    @patient_idn = PatientIdentifier.find_by(patient_id: patient_id)
    @patient_o_idn = PatientOtherIdentifier.find_by(patient_id: patient_id)

    @currency = Currency.find_by(id: current_facility.currency_id.to_s)

    @inventory_item_cart = Inventory::Department::Item.where('stock' => { '$gte' => 1 }, in_cart: true, is_deleted: false, facility_id: current_facility.id, department_id: params[:department_id])
    @invoice_inventory_department_pharmacy = Invoice::Inventories::Department::PharmacyInvoice.new
    @invoice_inventory_department_pharmacy.items.build
    respond_to do |format|
      format.js {}
    end
  end

  def create
    params.permit!
    facility_id = current_facility.id
    new_params = params['invoice_inventories_department_pharmacy_invoice']
    items = []
    if new_params['items_attributes'].present?
      if new_params['items_attributes'].values.present?
        new_params['items_attributes'].values.each do |item|
          items.push(item) if item[:lot_id].present?
        end
      end
    end
    non_inventory_items = new_params['non_inventory_items']
    department_id = '284748001'
    bill_number = Invoice::Inventories::Department::PharmacyHelper.increment_and_create_bill_number(facility_id)
    @pharmacy_log = Invoice::Inventories::Department::PharmacyInvoice.new
    @pharmacy_log.prescription_id = new_params['prescription_id']
    @pharmacy_log.recipient = new_params['recipient']
    @pharmacy_log.doctor_name = new_params['doctor_name']
    @pharmacy_log.patient_id = new_params['patient_id']
    @pharmacy_log.patient_identifier = new_params['patient_identifier']
    @pharmacy_log.recipient_mobile = new_params['recipient_mobile']
    @pharmacy_log.facility_id = facility_id
    @pharmacy_log.discount = new_params['discount']
    @pharmacy_log.advance_payment = new_params['advance_amount']
    @pharmacy_log.bill_number = bill_number
    @pharmacy_log.mode_of_payment = new_params['mode_of_payment']
    @pharmacy_log.total = new_params['total']
    @pharmacy_log.note = new_params['note']
    @pharmacy_log.specialty_id = new_params['specialty_id']

    @pharmacy_log.order_date =  Time.current
    @pharmacy_log.checkout_date = Time.current
    if new_params['tax_breakup'].present?
      new_params['tax_breakup'].each do |tax|
        @pharmacy_log.tax_breakup << tax.to_h
      end
    end

    @pharmacy_log.non_taxable_amount = new_params['non_taxable_amount']
    @pharmacy_log.tax_enabled = new_params['tax_enabled']
    @pharmacy_log.currency_symbol = new_params['currency_symbol']
    @pharmacy_log.currency_id = new_params['currency_id']
    @pharmacy_log.comments = new_params['comments']
    @pharmacy_log.organisation_id = current_user.organisation_id
    total_price = 0

    if items.present?
      if @pharmacy_log.save!
        if new_params['prescription_id'].present?
          # PatientPrescription.find_by(id: new_params['prescription_id']).update(dispatched_from_pharmacy: true, mark_converted_by: current_user.id, converted: true, encounterdate: Time.current)
          patient_prescriptions = PatientPrescription.find_by(id: new_params['prescription_id'])
          patient_prescriptions.update(dispatched_from_pharmacy: true, mark_converted_by: current_user.id, converted: true, encounterdate: Time.current, converted_date: Date.current, converted_datetime: Time.current)
          InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', patient_prescriptions.id.to_s)
        end
        count = 0
        items.each do |item|
          if item['inventory_item_id'].present?

            pharmacy_item = Inventory::Department::Item.find_by(facility_id: facility_id, id: item['inventory_item_id'], department_id: department_id)
            next if item['quantity'].to_i > pharmacy_item.stock

            lots = pharmacy_item.lots.where(id: item[:lot_id])

            quantity = item['quantity'].to_i
            lot_id_hash = {}

            lots.each do |lot|
              log_item = @pharmacy_log.items.new(create_pharmacy_log_item_params(pharmacy_item, lot))
              log_item.inventory_item_id = pharmacy_item.id
              log_item.mrp = lot.mrp
              log_item.list_price = lot.list_price
              log_item.expiry = lot.expiry
              log_item.batch_no = lot.batch_no
              next unless log_item.save

              next unless lot.stock >= quantity

              log_item.update_attributes(quantity: quantity)
              lot_id_hash[lot.id.to_s] = quantity
              lot.update_attributes(stock: lot.stock - quantity)
              log_item.update(lot_id_hash: lot_id_hash)
              # log_item.update(lot_id_hash: lot_id_hash)
              if item['tax_group'].present?
                item['tax_group'].each do |tax|
                  log_item.tax_group << tax.to_h
                end
              end
              if item['tax_group'].present?
                item['tax_group'].each do |tax_group|
                  log_item.tax_group << tax_group.to_h
                end
              end
              log_item.tax_group_id = item['tax_group_id']
              log_item.tax_inclusive = item['tax_inclusive']
              log_item.non_taxable_amount = item['non_taxable_amount']
              log_item.taxable_amount = item['taxable_amount']

              log_item.update!
            end
            pharmacy_item.update_attributes(stock: pharmacy_item.calculate_stock, checkout_count: (pharmacy_item.checkout_count || 0) + 1)
          else

            log_item = @pharmacy_log.items.new

            log_item.item_code = value['item_code']
            log_item.description = value['description']
            log_item.color = value['color']
            log_item.manufacturer = value['manufacturer']
            log_item.batch_no = value['batch_no']
            log_item.expiry = value['expiry']
            log_item.quantity = value['quantity']
            log_item.list_price = if value['list_price'].nil?
                                    value['mrp']
                                  else
                                    value['list_price']
                                  end
            log_item.mrp = value['mrp']
            log_item.vat = value['vat']
            log_item.non_inventory_item = true
            if value['tax_group'].present?
              value['tax_group'].each do |tax|
                log_item.tax_group << tax.to_h
              end
            end
            if value['tax_group'].present?
              value['tax_group'].each do |tax_group|
                log_item.tax_group << tax_group.to_h
              end
            end
            log_item.tax_group_id = value['tax_group_id']
            log_item.tax_inclusive = value['tax_inclusive']
            log_item.non_taxable_amount = value['non_taxable_amount']
            log_item.taxable_amount = value['taxable_amount']
            log_item.save(validate: false)
          end
          count = count.to_i + 1
        end
      end
    end

    # TaxCalculation
    if new_params['prescription_id'].present?
      Analytics::Conversion::PharmacyPrescriptionJob.perform_later(new_params['prescription_id'].to_s, current_user.id.to_s, 'Pharmacy')
    end
    Analytics::Financial::FinancialJob.perform_later(@pharmacy_log.id.to_s, 'Pharmacy')
    TaxCalculationJob.perform_later(@pharmacy_log.id.to_s, 'tax_collected_details') if @pharmacy_log.tax_enabled
    @invoice_inventory_department_pharmacy = Invoice::Inventories::Department::PharmacyInvoice.find_by(id: @pharmacy_log.id)
    @request_logs = PatientPrescription.where(facility_id: current_facility.id, dispatched_from_pharmacy: false).order('created_at DESC')

    if items.present?
      @invoice_inventory_department_pharmacy.items.each do |item|
        item.delete if item.quantity.to_i < 1
      end

      respond_to do |format|
        format.js { render 'show', layout: false }
      end
    else
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Warning', text: 'Please add atleast one item first.', type: 'warning' }); notice.get().click(function(){ notice.remove() });" }
      end
    end

    Analytics::Financial::InventoryPaymentModeJob.perform_later(@pharmacy_log.id.to_s) if @pharmacy_log.present?

    # redirect_to '/invoice/inventories/department/pharmacy_invoices/'+@pharmacy_log.id
  end

  # GET /invoice/inventory/department/pharmacies/1/edit
  def edit
    @pharmacy_log = Invoice::Inventories::Department::PharmacyInvoice.find(params[:id])
    @pharmacy_log_items = @pharmacy_log.items
    if @pharmacy_log.patient_id.present?
      @patient = Patient.find(@pharmacy_log.patient_id)
      @patient_idn = PatientIdentifier.where(patient_id: @pharmacy_log.patient_id)
    end
  end

  # PATCH/PUT /invoice/inventory/department/pharmacies/1
  # PATCH/PUT /invoice/inventory/department/pharmacies/1.json
  def update
    # invoice = Invoice.find(params[:id])
    # @pharmacy_return =  Invoice::Inventories::Department::PharmacyReturn.new(invoice.attributes.except("_id", "_type", "created_at", "updated_at", "items"))
    # @pharmacy_return.invoice_id = invoice.id
    # @pharmacy_return.bill_number = @pharmacy_return.bill_number + "RT"
    # @pharmacy_return.return_amount = params[:return_amount]

    # items = params[:items]

    # if @pharmacy_return.save(:validate => false)
    #   for key, value in items
    #     next unless key["return_quantity"].to_i > 0
    #     next if key["mrp"].nil?
    #     return_item = @pharmacy_return.items.new(key.permit(:description, :batch_no, :barcode, :price, :mark_up, :mrp, :list_price, :vendor, :manufacturer, :expiry, :inventory_item_id))
    #     return_item.quantity = key["return_quantity"]
    #     if return_item.save
    #       inventory_item = Inventory::Department::Item.find(return_item.inventory_item_id)
    #       inventory_item_lot = inventory_item.lots.find_by(batch_no: return_item.batch_no)

    #       # if inventory_item_lot
    #       inventory_item_lot.stock += return_item.quantity
    #       inventory_item_lot.empty = false
    #       if inventory_item_lot.save!
    #         inventory_item.update_attributes(stock: inventory_item.calculate_stock)
    #       end
    #     end

    #   end
    # end

    # respond_to do |format|
    #   format.json { render json: @pharmacy_return }

    # end
    # fail
    facility_id = current_facility.id
    new_params = params[:invoice_inventories_department_pharmacy_invoice]
    requested_items = new_params[:items_attributes]

    non_inventory_items = new_params[:non_inventory_items]
    department_id = '284748001'
    bill_number = Invoice::Inventories::Department::PharmacyHelper.increment_and_create_bill_number(facility_id)
    @pharmacy_log = Invoice::Inventories::Department::PharmacyInvoice.find(new_params[:id])
    # fail

    @pharmacy_log.update_attributes(recipient: new_params[:recipient], doctor_name: new_params[:consultant_name], patient_identifier: new_params[:patient_identifier], recipient_mobile: new_params[:recipient_mobile], facility_id: facility_id, discount: new_params[:discount], advance_payment: new_params[:advance_amount], bill_number: bill_number, total: new_params[:total], note: new_params[:note])
    total_price = 0

    # delete pharmacy_log_item and update pharmacy_item stock and respective lot

    requested_items.each do |_itemkey, item|
      log_item = @pharmacy_log.items.find(item['id'])
      if log_item.present?
        if item['inventory_item_id'].present?
          pharmacy_item = Inventory::Department::Item.find_by(facility_id: facility_id, id: item['inventory_item_id'], department_id: department_id)
          log_item.lot_id_hash.each do |key, value|
            @lot = Inventory::Department::Item::Lot.find(key)
            @lot.update(stock: @lot.stock + value)
          end
          log_item.delete
        else

          log_item.update(item_code: item['item_code'], description: item['description'], color: item['color'], manufacturer: item['manufacturer'], batch_no: item['batch_no'], expiry: item['expiry'], quantity: item['quantity'], mrp: item['mrp'], vat: item['vat'], non_inventory_item: true)
        end
      end
    end

    requested_items.each do |_key, value|
      if value.values_at('inventory_item_id')[0].present?
        pharmacy_item = Inventory::Department::Item.find_by(facility_id: facility_id, id: value['inventory_item_id'], department_id: department_id)

        next if value.values_at('quantity')[0].to_i > pharmacy_item.stock

        lots = pharmacy_item.lots.where(empty: false, is_deleted: false).order('expiry asc')
        # value['quantity'] not working so 'value.values_at("quantity")[0].to_i' is used
        quantity = value.values_at('quantity')[0].to_i
        lot_id_hash = {}
        lots.each do |lot|
          log_item = @pharmacy_log.items.new(create_pharmacy_log_item_params(pharmacy_item, lot))
          log_item.inventory_item_id = pharmacy_item.id
          log_item.price = lot.price
          log_item.list_price = lot.list_price
          log_item.expiry = lot.expiry
          log_item.batch_no = lot.batch_no

          if log_item.save

            if quantity >= lot.stock
              log_item.update_attributes(quantity: lot.stock)
              lot_id_hash[lot.id.to_s] = lot.stock
              quantity -= lot.stock
              lot.update_attributes(stock: 0, empty: true)
              log_item.update(lot_id_hash: lot_id_hash)

            elsif lot.stock > quantity
              log_item.update_attributes(quantity: quantity)
              lot_id_hash[lot.id.to_s] = quantity
              lot.update_attributes(stock: lot.stock - quantity)
              quantity = lot.stock - quantity
              log_item.update(lot_id_hash: lot_id_hash)

              break
            end
          end
        end
        # end
        pharmacy_item.update_attributes(stock: pharmacy_item.calculate_stock, checkout_count: (pharmacy_item.checkout_count || 0) + 1)
      # else
      # log_item = @pharmacy_log.items.
      #   log_item = item.update(item_code: value["item_code"],description: value["description"], color: value["color"], manufacturer: value["brand"], batch_no: value["batch_no"], expiry: value["expiry"], quantity: value["quantity"], mrp: value["price"], vat: value["vat"], non_inventory_item: true)
      # log_item.save(validate: false)
      # end
      else
        log_item = @pharmacy_log.items.find(value['id'])
        unless log_item.present?
          log_item = @pharmacy_log.items.new(item_code: value['item_code'], description: value['description'], color: value['color'], manufacturer: value['manufacturer'], batch_no: value['batch_no'], expiry: value['expiry'], quantity: value['quantity'], mrp: value['mrp'], vat: value['vat'], non_inventory_item: true)
          log_item.save(validate: false)
        end
      end
    end

    quantity_array = @pharmacy_log.items.all.pluck(:quantity).collect { |x| x.nil? ? 0 : x }
    mrp_array = @pharmacy_log.items.all.pluck(:price).collect { |x| x.nil? ? 0 : x }
    pharmacy_discount = @pharmacy_log.discount || 0
    total_price = number_with_precision(quantity_array.zip(mrp_array).map { |i, j| i.to_f * j.to_f }.sum, precision: 2).to_f
    @pharmacy_log.total = total_price - pharmacy_discount

    redirect_to '/invoice/inventories/department/pharmacy_invoices/' + @pharmacy_log.id
  end

  # GET /invoice/inventory/department/pharmacies/1
  # GET /invoice/inventory/department/pharmacies/1.json
  def show
    @request_logs = PatientPrescription.where(facility_id: current_facility.id, dispatched_from_pharmacy: false).order('created_at DESC')
    @pharmacy_log = Invoice::Inventories::Department::PharmacyInvoice.find(params[:id])
  end

  # DELETE /invoice/inventory/department/pharmacies/1
  # DELETE /invoice/inventory/department/pharmacies/1.json
  def destroy
    @invoice_inventory_department_pharmacy.destroy
    respond_to do |format|
      format.html { redirect_to invoice_inventory_department_pharmacies_url }
      format.json { head :no_content }
    end
  end

  def print_invoice
    log_id = params[:log_id]
    page_size = params[:page_size]
    facility_id = current_facility.id
    @pharmacy_log = Invoice::Inventories::Department::PharmacyInvoice.find(log_id)
    @department = Inventory::Department.find_by(department_id: '284748001', facility_id: facility_id)
    @facility = Facility.find(facility_id)
    @patient_id = @pharmacy_log.patient_id
    @mr_no = PatientOtherIdentifier.find_by(patient_id: @patient_id).try(:mr_no)
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    html_template = if @pharmacy_log.tax_enabled
                      'invoice/inventories/department/pharmacy_invoices/print_invoice_tax_enabled'
                    else
                      'invoice/inventories/department/pharmacy_invoices/print_invoice_tax_disabled'
                    end

    if page_size == 'A5'
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pharmacy/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    else
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pharmacy/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', orientation: 'Portrait', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    end
  end

  def delete_old_request
    if params[:department] == '284748001'
      PatientPrescription.where(:created_at.lte => (Date.current - 7), :facility_id => current_facility.id).each do |log|
        log.update_attributes(dispatched_from_pharmacy: true)
      end
    elsif params[:department] == '50121007'
      PatientOpticalPrescription.where(:created_at.lte => (Date.current - 7)).each do |log|
        log.update_attributes(dispatched_from_optical: true)
      end
    end
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def search_pharmacy_item
    if params[:q].present?
      @pharmacy_items = Inventory::Department::Item.where(is_deleted: false, 'stock' => { '$gte' => 1 }, department_id: '284748001', facility_id: current_facility.id, item_code: /#{Regexp.escape(params[:q])}/i)
    else
      head :no_content
    end
  end

  def search_pharmacy_item_description
    if params[:q].present?
      @pharmacy_items = Inventory::Department::Item.where(is_deleted: false, 'stock' => { '$gte' => 1 }, department_id: '284748001', facility_id: current_facility.id, description: /#{Regexp.escape(params[:q])}/i)
      respond_to do |format|
        format.json { render 'search_pharmacy_item' }
      end
    else
      head :no_content
    end
  end

  def search_pharmacy_checkout_log
    facility_id = current_facility.id
    @invoice_inventory_department_pharmacies = Invoice::Inventories::Department::PharmacyInvoice.where(facility_id: facility_id, bill_number: /#{Regexp.escape(params[:q])}/i).newest_first
    respond_to do |format|
      format.js {}
    end
  end

  # GET /invoice/inventory/department/pharmacies
  # GET /invoice/inventory/department/pharmacies.json
  def free_invoice
    @department_id = params[:department_id]
    redirect_to patients_search_path(url: '/patients/new', url_department: '/invoice/inventories/department/pharmacy_invoices/new', department_id: @department_id, modal: 'free-invoice-inventory-modal')
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

  def proceed_free_invoice
    @patienttype = params[:patienttype]
    @department_id = params[:department_id]

    if @patienttype == 'Fresh'
      name = params[:name]
      mr_no = params[:mr_no]
      mobile_no = params[:mobile_no]
      age = params[:age]
      address = params[:address]
      organisation = current_user.organisation

      hg_patient = Patient.new(fullname: name, age: age, mobilenumber: mobile_no.to_s, address_1: address.to_s, reg_hosp_ids: [organisation.id.to_s])

      patsplit = name.split(' ')
      if patsplit.count == 1
        hg_patient.firstname = patsplit[0]
      elsif patsplit.count == 2
        if patsplit[0].capitalize == 'Mr.' || patsplit[0].capitalize == 'Mr' || patsplit[0].capitalize == 'Mrs' || patsplit[0].capitalize == 'Mrs.' || patsplit[0].capitalize == 'Dr.' || patsplit[0].capitalize == 'Dr'
          hg_patient.firstname = patsplit.join(' ')
        else
          hg_patient.firstname = patsplit[0]
          hg_patient.lastname = patsplit[1]
        end
      elsif patsplit.count > 2
        hg_patient.lastname = patsplit[patsplit.count - 1]
        patsplit.delete_at(patsplit.count - 1)
        hg_patient.firstname = patsplit.join(' ')
      end

      if hg_patient.save!
        PatientIdentifier.create(patient_id: hg_patient.id, organisation_id: organisation.id.to_s, patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
        attrs = { :patient_id => hg_patient.id, 'patientpersonalhistory_attributes' => { problems: [], 'flag' => 1 }, 'patientallergyhistory_attributes' => { flag: 1, antimicrobialagents: [], nsaids: [], antifungalagents: [], antiviralagents: [], contact: [], food: [], eyedrops: [], others: '' } }
        PatientHistory.create(attrs)

        unless mr_no == ''
          patient_other_identifier = PatientOtherIdentifier.new
          patient_other_identifier.mr_no = mr_no
          patient_other_identifier.patient_id = hg_patient.id
          patient_other_identifier.organisation_id = current_user.organisation.id
          patient_other_identifier.facility_id = current_facility.id
          patient_other_identifier.save
        end

      end
      @patient_id = hg_patient.id

    elsif @patienttype == 'Followup'
      @patient_id = params[:patient_id]
    end

    if @patient_id.present?
      redirect_to "/invoice/inventories/department/pharmacy_invoices/new?patient_id=#{@patient_id}&&department_id=#{@department_id}"
    else
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Error', text: 'Please fill the patient data correctly', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end

      #   render :nothing => true
    end
  end

  def patient_prescription
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)
    @patient_prescription = PatientPrescription.find_by(id: params[:prescription_id])
    @patient = Patient.find_by(id: @patient_prescription.patient_id)
    @patient_idn = PatientIdentifier.find_by(patient_id: @patient_prescription.patient_id)
    @patient_o_idn = PatientOtherIdentifier.find_by(patient_id: @patient_prescription.patient_id)
    @invoice_inventory_department_pharmacy = Invoice::Inventories::Department::PharmacyInvoice.new
    # @invoice_inventory_department_pharmacy.items.build
    @currency = Currency.find_by(id: current_facility.currency_id.to_s)

    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ['284748001'])
  end

  def delete_order
    @prescription = PatientPrescription.find_by(id: params[:id])
    @prescription.update(is_deleted: true)
    InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', @prescription.id.to_s)
  end

  # def print_return
  #   return_id = params[:return_id]

  #   @organisation = current_user.organisation
  #   @pharmacy_log = Invoice::Inventories::Department::PharmacyReturn.find(return_id)
  #   # render :template => "invoice/inventory/department/pharmacy_invoices/print_invoice", :pdf => "xyz", :layout => 'invoice/inventory/pharmacy/pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A5", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?

  #   respond_to do |format|
  #     format.html {render :template => "invoice/inventories/department/pharmacy_invoices/print_return.html.erb", :pdf => "xyz", :layout => 'invoice/inventory/pharmacy/pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :show_as_html => params[:debug].present?, :footer => { :right => '[page] of [topage]' }}
  #   end
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_invoice_inventory_department_pharmacy
    @invoice_inventory_department_pharmacy = Invoice::Inventories::Department::PharmacyInvoice.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def invoice_inventory_department_pharmacy_params
    params[:invoice_inventory_department_pharmacy]
  end

  def create_pharmacy_log_item_params(item, lot)
    objs = ActionController::Parameters.new(item.as_json.merge(lot.as_json))
    objs.permit(:item_code, :barcode, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :brand, :expiry, :description, :manufacturer)
  end
end
