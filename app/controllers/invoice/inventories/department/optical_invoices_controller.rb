class Invoice::Inventories::Department::OpticalInvoicesController < ApplicationController
  before_action :authorize
  before_action :set_invoice_inventory_department_optical, only: [:show, :edit, :update, :destroy]
  include Invoice::Inventories::Department::OpticalHelper

  def index
    facility_id = current_facility.id
    @invoice_inventory_department_opticals = Invoice::Inventories::Department::OpticalInvoice.where(facility_id: facility_id, payment_completed: true).checkout_first.limit(10)
  end

  def show_more_checkout_log
    @count = params[:count]
    facility_id = current_facility.id
    @invoice_inventory_department_opticals = Invoice::Inventories::Department::OpticalInvoice.where(facility_id: facility_id, payment_completed: true).checkout_first.skip(params[:count].to_i).limit(10)
    respond_to do |format|
      format.js {}
    end
  end

  def advance_patient_list
    facility_id = current_facility.id
    @invoice_inventory_department_opticals = Invoice::Inventories::Department::OpticalInvoice.where(facility_id: facility_id, payment_completed: false, advance_taken: true).ordered_first
  end

  # GET /invoice/inventory/department/opticals/1
  # GET /invoice/inventory/department/opticals/1.json
  def checkout_bill # checkout advance bill to payment done
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.find(params[:id])
  end

  def payment_done
    facility_id = current_facility.id
    log_id = params[:log_id]
    page_size = params[:page_size]
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.find(log_id)
    @department = Inventory::Department.find_by(department_id: '50121007', facility_id: facility_id)
    @facility = Facility.find(facility_id)
    @optical_log.advance_payment = ''
    @optical_log.payment_completed = true
    @optical_log.checkout_date = Time.current

    @optical_log.save(validate: false)

    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    html_template = if @optical_log.tax_enabled
                      'invoice/inventories/department/optical_invoices/print_invoice_tax_enabled'
                    else
                      'invoice/inventories/department/optical_invoices/print_invoice_tax_disabled'
                    end

    if page_size == 'A5'
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    else
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', orientation: 'Portrait', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    end
  end

  def show
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.find(params[:id])
  end

  # GET /invoice/inventory/department/opticals/new
  def new
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)
    patient_id = params[:patient_id]
    @patient = Patient.find(patient_id)
    @patient_idn = PatientIdentifier.find_by(patient_id: patient_id)
    @patient_o_idn = PatientOtherIdentifier.find_by(patient_id: patient_id)

    @currency = Currency.find_by(id: current_facility.currency_id.to_s)

    @inventory_item_cart = Inventory::Department::Item.where('stock' => { '$gte' => 1 }, in_cart: true, is_deleted: false, facility_id: current_facility.id, department_id: params[:department_id])

    @invoice_inventory_department_optical = Invoice::Inventories::Department::OpticalInvoice.new
    @invoice_inventory_department_optical.items.build
    respond_to do |format|
      format.js {}
    end
  end

  # POST /invoice/inventory/department/opticals
  # POST /invoice/inventory/department/opticals.json
  # :_id => :"bson/object_id",
  #            :_type => :string,
  #     :admission_id => :object,
  #  :advance_payment => :float,
  #   :appointment_id => :object,
  #             :card => :float,
  #             :cash => :float,
  #       :created_at => :time,
  #         :discount => :float,
  #       :invoice_id => :string,
  #  :mode_of_payment => :string,
  #       :patient_id => :object,
  #              :tax => :float,
  #            :total => :float,
  #       :updated_at => :time,
  #          :user_id => :object
  def create
    facility_id = current_facility.id
    new_params = params[:invoice_inventories_department_optical_invoice]
    bill_number = Invoice::Inventories::Department::OpticalHelper.increment_and_create_bill_number(facility_id)
    items = new_params[:items_attributes]
    services = new_params[:services]
    non_inventory_items = params[:non_inventory_items]
    advance_taken = new_params[:advance_taken]
    payment_completed = if advance_taken == 'false'
                          'true'
                        else
                          'false'
                        end
    department_id = '50121007'
    department = Inventory::Department.find_by(department_id: '50121007', facility_id: facility_id)
    # department.update_attributes(shop_name: params[:shop_name], shop_address: params[:shop_address])
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.new
    @optical_log.recipient = new_params[:recipient]
    @optical_log.prescription_id = new_params[:prescription_id]
    @optical_log.doctor_name = new_params[:doctor_name]
    @optical_log.patient_id = new_params[:patient_id]
    @optical_log.patient_identifier = new_params[:patient_identifier]
    @optical_log.recipient_mobile = new_params[:recipient_mobile]
    @optical_log.recipient_email = new_params[:recipient_email]
    @optical_log.facility_id = facility_id
    @optical_log.specialty_id = '309988001'
    @optical_log.delivery_date = new_params[:delivery_date]
    @optical_log.discount = new_params[:discount]
    @optical_log.advance_payment = new_params[:advance_payment]
    @optical_log.note = new_params[:note]
    @optical_log.bill_number = bill_number
    @optical_log.notify_type = new_params[:notify_type]
    @optical_log.notify = new_params[:notify_type] ? true : false,
                          @optical_log.advance_taken = advance_taken
    @optical_log.payment_completed = payment_completed
    @optical_log.order_date =  Time.current
    @optical_log.checkout_date = Time.current
    @optical_log.total = new_params[:total]
    if new_params[:tax_breakup].present?
      new_params[:tax_breakup].each do |tax|
        tax_breakup = { "_id": tax[:_id], "name": tax[:name], "amount": tax[:amount] }
        @optical_log.tax_breakup << tax_breakup
      end
    end
    @optical_log.non_taxable_amount = new_params[:non_taxable_amount]
    @optical_log.tax_enabled = new_params[:tax_enabled]
    @optical_log.currency_id = new_params[:currency_id]
    @optical_log.currency_symbol = new_params[:currency_symbol]
    @optical_log.mode_of_payment = new_params[:mode_of_payment]
    @optical_log.comments = new_params[:comments]
    @optical_log.organisation_id = current_user.organisation_id
    total_price = 0
    if @optical_log.save(validate: false)
      if new_params[:prescription_id].present?
        # PatientOpticalPrescription.find(new_params[:prescription_id]).update(dispatched_from_optical: true, mark_converted_by: current_user.id, converted: true, encounterdate: Time.current)
        PatientOpticalPrescription.find(new_params[:prescription_id]).update(dispatched_from_optical: true, mark_converted_by: current_user.id, converted: true, encounterdate: Time.current, converted_date: Date.current, converted_datetime: Time.current)
      end
      items.each do |_key, value|
        if value.values_at('inventory_item_id')[0].present?
          optical_item = Inventory::Department::Item.find_by(facility_id: facility_id, id: value['inventory_item_id'], department_id: department_id)
          next if value.values_at('quantity')[0].to_i > optical_item.stock

          lots = optical_item.lots.where(empty: false, is_deleted: false).order('expiry asc')
          # value['quantity'] not working so 'value.values_at("quantity")[0].to_i' is used
          quantity = value.values_at('quantity')[0].to_i
          lot_id_hash = {}
          lots.each do |lot|
            log_item = @optical_log.items.new(create_optical_log_item_params(optical_item, lot))
            log_item.inventory_item_id = optical_item.id
            log_item.mrp = lot.mrp
            log_item.list_price = lot.list_price
            log_item.expiry = lot.expiry
            log_item.batch_no = lot.batch_no
            log_item.vat = value.values_at('vat')[0]
            next unless log_item.save

            # if quantity >= lot.stock
            #   log_item.update_attributes(quantity: lot.stock)
            #   lot_id_hash[lot.id.to_s] = lot.stock
            #   quantity = quantity - lot.stock
            #   lot.update_attributes(stock: 0, empty: true)
            #   log_item.update(lot_id_hash: lot_id_hash)

            next unless lot.stock >= quantity

            log_item.update_attributes(quantity: quantity)
            lot_id_hash[lot.id.to_s] = quantity
            lot.update_attributes(stock: lot.stock - quantity)
            quantity = lot.stock - quantity
            log_item.update(lot_id_hash: lot_id_hash)
            # log_item.update(tax_group: value['tax_group'], tax_group_id: value['tax_group_id'], tax_inclusive: value['tax_inclusive'], non_taxable_amount: value['non_taxable_amount'], taxable_amount: value['taxable_amount'])
            if value['tax_group'].present?
              value['tax_group'].each do |tax|
                tax_breakup = { "_id": tax[:_id], "name": tax[:name], "amount": tax[:amount] }
                log_item.tax_group << tax_breakup
              end
            end
            log_item.tax_group_id = value['tax_group_id']
            log_item.tax_inclusive = value['tax_inclusive']
            log_item.non_taxable_amount = value['non_taxable_amount']
            log_item.taxable_amount = value['taxable_amount']
            log_item.update!
            break
          end
          # end
          optical_item.update_attributes(stock: optical_item.calculate_stock, checkout_count: (optical_item.checkout_count || 0) + 1)
        else
          log_item = @optical_log.items.new
          log_item.item_code = value['item_code']
          log_item.description = value['description']
          log_item.color = value['color']
          log_item.brand = value['brand']
          log_item.batch_no = value['batch_no']
          log_item.expiry = value['expiry']
          log_item.quantity = value['quantity']
          log_item.list_price = value['list_price']
          log_item.mrp = value['mrp']
          log_item.vat = value['vat']
          log_item.non_inventory_item = true
          if value['tax_group'].present?
            value['tax_group'].each do |tax|
              tax_breakup = { "_id": tax[:_id], "name": tax[:name], "amount": tax[:amount] }
              log_item.tax_group << tax_breakup
            end
          end
          log_item.tax_group_id = value['tax_group_id']
          log_item.tax_inclusive = value['tax_inclusive']
          log_item.non_taxable_amount = value['non_taxable_amount']
          log_item.taxable_amount = value['taxable_amount']
          log_item.save(validate: false)
        end
      end
      services&.each do |_key, value|
        log_item = @optical_log.items.new(description: value['description'], mrp: value['mrp'], service: true, quantity: 1, vat: 0)
        if log_item.save
        end
      end
      # if non_inventory_items
      #   for key, value in non_inventory_items
      #     log_item = @optical_log.items.new(item_code: value["item_code"],description: value["description"], color: value["color"], brand: value["brand"], quantity: value["request_quantity"], mrp: value["mrp"], vat: value["vat_amt"], non_inventory_item: true)
      #     if log_item.save
      #     end
      #   end
      # end
      quantity_array = @optical_log.items.all.pluck(:quantity).collect { |x| x.nil? ? 0 : x }
      mrp_array = @optical_log.items.all.pluck(:list_price).collect { |x| x.nil? ? 0 : x }

      unless @optical_log.tax_enabled
        vat_array = @optical_log.items.all.pluck(:vat).collect { |x| x.nil? ? 0 : x }
        # '.collect { |x| x.nil? ? 0:x }' coverts nil value to 0
        optical_discount = @optical_log.discount || 0
        if quantity_array.present? && mrp_array.present? && vat_array.present?
          total_mrp = quantity_array.zip(mrp_array).map { |i, j| i.to_f * j.to_f }.sum
          total_vat_array = mrp_array.zip(vat_array).map { |i, j| i.to_f * j.to_f / 100 }
          total_vat = total_vat_array.zip(quantity_array).map { |i, j| i.to_f * j.to_f }.sum
          @optical_log.total = total_mrp + total_vat - optical_discount
        end
      end
      print "Updated total price of log to #{@optical_log.try(:total)}" if @optical_log.save(validate: false)
    end
    # TaxCalculation
    if new_params[:prescription_id].present?
      Analytics::Conversion::OpticalPrescriptionJob.perform_later(new_params[:prescription_id].to_s, current_user.id.to_s, 'Optical')
    end

    Analytics::Financial::FinancialJob.perform_later(@optical_log.id.to_s, 'Optical')
    TaxCalculationJob.perform_later(@optical_log.id.to_s, 'tax_collected_details') if @optical_log.tax_enabled

    Analytics::Financial::InventoryPaymentModeJob.perform_later(@optical_log.id.to_s) if @optical_log.present?

    # @invoice_inventory_department_optical = Invoice::Inventories::Department::optical.new(invoice_inventory_department_optical_params)

    # respond_to do |format|
    #   if @invoice_inventory_department_optical.save
    #     format.html { redirect_to @invoice_inventory_department_optical, notice: 'optical was successfully created.' }
    #     format.json { render action: 'show', status: :created, location: @invoice_inventory_department_optical }
    #   else
    #     format.html { render action: 'new' }
    #     format.json { render json: @invoice_inventory_department_optical.errors, status: :unprocessable_entity }
    #   end
    # end
    redirect_to '/invoice/inventories/department/optical_invoices/' + @optical_log.id
  end

  # GET /invoice/inventory/department/opticals/1/edit
  def edit
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.find(params[:id])
    @optical_log_items = @optical_log.items
    # if @optical_log.patient_id.present?    here patient_id is actuallly patient identifier
    #   @patient = Patient.find(@optical_log.patient_id)
    #   @patient_idn = PatientIdentifier.where(patient_id: @optical_log.patient_id)
    # end
  end

  # PATCH/PUT /invoice/inventory/department/opticals/1
  # PATCH/PUT /invoice/inventory/department/opticals/1.json
  def update
    # invoice = Invoice.find(params[:id])
    # @optical_return =  Invoice::Inventories::Department::OpticalReturn.new(invoice.attributes.except("_id", "_type", "created_at", "updated_at", "items"))
    # @optical_return.invoice_id = invoice.id
    # @optical_return.bill_number = @optical_return.bill_number + "RT"
    # @optical_return.return_amount = params[:return_amount]

    # items = params[:items]

    # if @optical_return.save(:validate => false)
    #   for key, value in items
    #     next unless key["return_quantity"].to_i > 0
    #     next if key["service"] == true
    #     return_item = @optical_return.items.new(key.permit(:description, :batch_no, :barcode, :price, :mark_up, :mrp, :list_price, :vendor, :brand, :expiry, :inventory_item_id, :vat))
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
    #   format.json { render json: @optical_return }

    # end

    facility_id = current_facility.id
    new_params = params[:invoice_inventories_department_optical_invoice]

    requested_items = new_params[:items_attributes]

    non_inventory_items = new_params[:non_inventory_items]
    services = params[:services]
    department_id = '50121007'
    bill_number = Invoice::Inventories::Department::OpticalHelper.increment_and_create_bill_number(facility_id)
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.find(new_params[:id])
    @optical_log.update_attributes(recipient: new_params[:recipient], doctor_name: new_params[:doctor_name], patient_identifier: new_params[:patient_identifier], recipient_mobile: new_params[:recipient_mobile], recipient_email: new_params[:recipient_email], facility_id: facility_id, delivery_date: new_params[:delivery_date], discount: new_params[:discount], advance_payment: new_params[:advance_payment], note: new_params[:note], bill_number: bill_number, notify_type: new_params[:notify_type], notify: new_params[:notify_type] ? true : false)
    total_price = 0

    # delete optical_log_item and update optical_item stock and respective lot

    requested_items.each do |_key, value|
      next unless value.values_at('inventory_item_id')[0].present?

      optical_item = Inventory::Department::Item.find_by(facility_id: facility_id, id: value['inventory_item_id'], department_id: department_id)
      next if value.values_at('quantity')[0].to_i > optical_item.stock

      lots = optical_item.lots.where(empty: false, is_deleted: false).order('expiry asc')
      # value['quantity'] not working so 'value.values_at("quantity")[0].to_i' is used
      quantity = value.values_at('quantity')[0].to_i
      lot_id_hash = {}
      lots.each do |lot|
        log_item = @optical_log.items.new(create_optical_log_item_params(optical_item, lot))
        log_item.inventory_item_id = optical_item.id
        log_item.mrp = lot.mrp
        log_item.list_price = lot.list_price
        log_item.expiry = lot.expiry
        log_item.batch_no = lot.batch_no
        log_item.vat = value.values_at('vat')[0]
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
      optical_item.update_attributes(stock: optical_item.calculate_stock, checkout_count: (optical_item.checkout_count || 0) + 1)
      # else
      #   @optical_log.items.each do |item|
      #     log_item = item.update(item_code: value["item_code"],description: value["description"], color: value["color"], brand: value["brand"], batch_no: value["batch_no"], expiry: value["expiry"], quantity: value["quantity"], mrp: value["price"], vat: value["vat_amt"], non_inventory_item: true)
      #   end
    end

    services&.each do |_key, value|
      log_item = @optical_log.items.new(description: value['description'], mrp: value['mrp'], service: true, quantity: 1, vat: 0)
      if log_item.save
      end
    end

    quantity_array = @optical_log.items.all.pluck(:quantity).collect { |x| x.nil? ? 0 : x }
    mrp_array = @optical_log.items.all.pluck(:mrp).collect { |x| x.nil? ? 0 : x }
    vat_array = @optical_log.items.all.pluck(:vat).collect { |x| x.nil? ? 0 : x }
    # '.collect { |x| x.nil? ? 0:x }' coverts nil value to 0
    optical_discount = @optical_log.discount || 0
    if quantity_array.present? && mrp_array.present? && vat_array.present?
      total_mrp = quantity_array.zip(mrp_array).map { |i, j| i * j }.sum
      total_vat_array = mrp_array.zip(vat_array).map { |i, j| i * j / 100 }
      total_vat = total_vat_array.zip(quantity_array).map { |i, j| i * j }.sum
      @optical_log.total = total_mrp + total_vat - optical_discount
    end
    print "Updated total price of log to #{@optical_log.try(:total)}" if @optical_log.save(validate: false)

    redirect_to '/invoice/inventories/department/optical_invoices/' + @optical_log.id
  end

  def show
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.find(params[:id])
  end

  # DELETE /invoice/inventory/department/opticals/1
  # DELETE /invoice/inventory/department/opticals/1.json
  def destroy
    @invoice_inventory_department_optical.destroy
    respond_to do |format|
      format.html { redirect_to invoice_inventory_department_opticals_url }
      format.json { head :no_content }
    end
  end

  # GET /invoice/inventory/department/opticals
  # GET /invoice/inventory/department/opticals.json
  def free_invoice
    @department_id = params[:department_id]
    redirect_to patients_search_path(url: '/patients/new', url_department: '/invoice/inventories/department/optical_invoices/new', department_id: @department_id, modal: 'free-invoice-inventory-modal')
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

    redirect_to "/invoice/inventories/department/optical_invoices/new?patient_id=#{@patient_id}&&department_id=#{@department_id}"
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

  def advance_patient_list
    facility_id = current_facility.id
    @invoice_inventory_department_opticals = Invoice::Inventories::Department::OpticalInvoice.where(facility_id: facility_id, payment_completed: false, advance_taken: true).ordered_first
  end

  # GET /invoice/inventory/department/opticals/1
  # GET /invoice/inventory/department/opticals/1.json
  def checkout_bill # checkout advance bill to payment done
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.find(params[:id])
  end

  def payment_done
    facility_id = current_facility.id
    log_id = params[:log_id]
    page_size = params[:page_size]
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.find(log_id)
    @department = Inventory::Department.find_by(department_id: '50121007', facility_id: facility_id)
    @facility = Facility.find(facility_id)
    @optical_log.advance_payment = ''
    @optical_log.payment_completed = true
    @optical_log.checkout_date = Time.current

    @optical_log.save(validate: false)

    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    html_template = if @optical_log.tax_enabled
                      'invoice/inventories/department/optical_invoices/print_invoice_tax_enabled'
                    else
                      'invoice/inventories/department/optical_invoices/print_invoice_tax_disabled'
                    end
    if page_size == 'A5'
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    else
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', orientation: 'Portrait', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    end
  end

  def print_invoice
    # param = params[:log_id].split('hgraph')
    facility_id = current_facility.id
    log_id = params[:log_id]
    page_size = params[:page_size]
    @optical_log = Invoice::Inventories::Department::OpticalInvoice.find(log_id)
    @department = Inventory::Department.find_by(department_id: '50121007', facility_id: facility_id)
    @facility = Facility.find(facility_id)
    # @patient = PatientIdentifier.find_by(patient_org_id: @optical_log.patient_id).patient_id
    # PatientOpticalPrescription
    @advance_invoice = InventoryAdvancePayment.find(params[:log_id])

    # render :template => "invoice/inventory/department/optical_invoices/print_invoice", :pdf => "xyz", :layout => 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => {:spacing => 10,:html => {:template => 'layouts/pdf-header.html'}},:footer => {:html => { :template=>  'layouts/pdf-footer.html' },:spacing => 10, }, :margin => {:top=>40, :bottom => 40 }
    @print_advance = params[:p_adv]
    @optical_log.update_attributes(advance_amount: 0.0) if @print_advance == 'no'
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    html_template = if @optical_log.tax_enabled
                      'invoice/inventories/department/optical_invoices/print_invoice_tax_enabled'
                    else
                      'invoice/inventories/department/optical_invoices/print_invoice_tax_disabled'
                    end

    if page_size == 'A5'
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    else
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', orientation: 'Portrait', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    end
  end

  def print_advance_invoice
    @advance_invoice = InventoryAdvancePayment.find(params[:log_id])
    @department = Inventory::Department.find_by(department_id: '50121007', facility_id: current_facility.id)
    @facility = current_facility
    if params[:page_size] == 'a4'
      render template: 'invoice/inventories/department/optical_invoices/print_advance_invoice', pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', orientation: 'Portrait', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }
    else
      render template: 'invoice/inventories/department/optical_invoices/print_invoice', pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }
    end
  end

  # def print_return
  #   return_id = params[:return_id]

  #   @organisation = current_user.organisation
  #   @optical_log = Invoice::Inventories::Department::OpticalReturn.find(return_id)
  #   # render :template => "invoice/inventory/department/optical_invoices/print_invoice", :pdf => "xyz", :layout => 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A5", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?
  #   render :template => "invoice/inventories/department/optical_invoices/print_return", :pdf => "xyz", :layout => 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :show_as_html => params[:debug].present?, :footer => { :right => '[page] of [topage]' }
  # end

  def print_prescription
    prescription_id = params[:log_id]
    @prescription = PatientOpticalPrescription.find(prescription_id)
    @patient = @prescription.try(:patient)
    if @patient.present?
      render template: 'invoice/inventories/department/optical_invoices/print_prescription', pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }
    else
      head :no_content
    end
  end

  def notify_recipient
    OpticalJob.perform_later(params[:message], params[:recipient_mobile], params[:id]) if params[:message]
    OpticalEmail.perform_later(params[:email_body], params[:recipient_email], params[:id]) if params[:email_body]
    @recepient = Invoice::Inventories::Department::OpticalInvoice.find(params[:id])

    @recepient.sms = params[:message] if params[:message]

    @recepient.email = params[:email_body] if params[:email_body]
    @recepient.called = params[:called] if params[:called]
    @recepient.notified = true
    @recepient.save(validate: false)
    respond_to do |format|
      format.all { render nothing: true }
    end
  end

  def optical_prescription
    old_patient = PatientIdentifier.find_by(patient_org_id: params[:data]['patient_org_id'])

    if old_patient
      @patient_id = old_patient.patient_id
    else
      @patient = Patient.new(prescription_patient_params)
      @patient.fullname = params[:data]['fullname']
      @patient.reg_date = Date.current
      @patient.reg_time = Time.current
      @patient.save(validate: false)

      @patient_identifier = PatientIdentifier.create(patient_id: @patient.id, organisation_id: current_user.organisation.id.to_s, patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
      @patient_id = @patient.id
    end

    @prescription = PatientOpticalPrescription.new(prescription_params)
    @prescription.patient_id = @patient_id
    @prescription.user_id = current_user.id
    @prescription.facility_id = current_facility.id
    @prescription.dispatched_from_optical = true
    @prescription.prescription_date = Date.current
    @prescription.prescription_datetime = Time.current
    @prescription.save(validate: false)

    InventoryJobs::PrescriptionDataJob.perform_later('optical', @prescription.id.to_s)

    respond_to do |format|
      format.json do
        render json: { patient: @patient,
                       prescription: @prescription }
      end
    end
  end

  def print_optical_prescription
    @patient = Patient.find(params[:patient])
    @prescription = PatientOpticalPrescription.find(params[:prescription])
    render template: 'invoice/inventories/department/optical_invoices/print_prescription', pdf: 'xyz', layout: 'invoice/inventory/optical/pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }
  end

  def advance_invoice
    @advance_payment = InventoryAdvancePayment.create(advance_invoice_params)

    advance_amount = []
    advance_reason = []
    @prescription = PatientOpticalPrescription.find_by(display_id: @advance_payment.prescription_id)
    advance_amount = @prescription.advance_amount
    advance_reason = @prescription.advance_reason
    advance_amount.push(@advance_payment.advance_amount)
    advance_reason.push(@advance_payment.reason)

    @prescription.update_attributes(advance_amount: advance_amount, advance_reason: advance_reason)
    @advance_payment.update(facility_id: current_facility.id, patient_id: @prescription.patient_id.to_s, appointment_id: @prescription.appointment_id, doctor_name: @prescription.consultant_name)

    respond_to do |format|
      format.js
    end
  end

  def update_advance_invoice
    advance_amount = []
    @advance_payment = InventoryAdvancePayment.find(params[:advance_invoice_data][:id].to_s)
    delete_advance_amount = @advance_payment.advance_amount
    delete_advance_reason = @advance_payment.reason
    @advance_payment.update(advance_invoice_params)
    @prescription = PatientOpticalPrescription.find_by(display_id: @advance_payment.prescription_id, facility_id: current_facility.id)

    advance_amount = @prescription.advance_amount
    advance_reason = @prescription.advance_reason

    advance_amount.slice!(advance_amount.index(delete_advance_amount))
    advance_amount.push(@advance_payment.advance_amount)
    advance_reason.slice!(advance_reason.index(delete_advance_reason))
    advance_reason.push(@advance_payment.reason)
    @prescription.update_attributes(advance_amount: advance_amount, advance_reason: advance_reason)
    InventoryJobs::PrescriptionDataJob.perform_later('optical', @prescription.id.to_s)
    respond_to do |format|
      format.js
    end
  end

  def search_optical_checkout_log
    facility_id = current_facility.id
    @invoice_inventory_department_opticals = Invoice::Inventories::Department::OpticalInvoice.where(facility_id: facility_id, payment_completed: true, bill_number: /#{Regexp.escape(params[:q])}/i).newest_first
    respond_to do |format|
      format.js {}
    end
  end

  def search_optical_advance_log
    facility_id = current_facility.id
    @invoice_inventory_department_opticals = Invoice::Inventories::Department::OpticalInvoice.where(facility_id: facility_id, payment_completed: false, advance_taken: true, bill_number: /#{Regexp.escape(params[:q])}/i).newest_first
    respond_to do |format|
      format.js {}
    end
  end

  def search_optical_item
    if params[:q].present?
      @optical_items = Inventory::Department::Item.where(is_deleted: false, 'stock' => { '$gte' => 1 }, department_id: '50121007', facility_id: current_facility.id, item_code: /#{Regexp.escape(params[:q])}/i)
    else
      head :no_content
    end
  end

  def search_optical_item_description
    if params[:q].present?
      @optical_items = Inventory::Department::Item.where(is_deleted: false, 'stock' => { '$gte' => 1 }, department_id: '50121007', facility_id: current_facility.id, description: /#{Regexp.escape(params[:q])}/i)
      respond_to do |format|
        format.json { render 'search_optical_item' }
      end
    else
      head :no_content
    end
  end

  def patient_optical_prescription
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)
    @patient_prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])
    @patient = Patient.find(@patient_prescription.patient_id)
    @patient_idn = PatientIdentifier.find_by(patient_id: @patient_prescription.patient_id)
    @patient_o_idn = PatientOtherIdentifier.find_by(patient_id: @patient_prescription.patient_id)
    @invoice_inventory_department_optical = Invoice::Inventories::Department::OpticalInvoice.new
    @invoice_inventory_department_optical.items.build
    @currency = Currency.find_by(id: current_facility.currency_id.to_s)

    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ['50121007'])
  end

  private

  # permit params
  # def invoice_inventories_department_optical_invoice_params
  #   params.require(:invoice_inventories_department_optical_invoice).permit(:tax_enabled, :tax_group)
  # end
  # Use callbacks to share common setup or constraints between actions.
  def set_invoice_inventory_department_optical
    @invoice_inventory_department_optical = Invoice::Inventories::Department::OpticalInvoice.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def invoice_inventory_department_optical_params
    params[:invoice_inventory_department_optical]
  end

  def create_optical_log_item_params(item, lot)
    objs = ActionController::Parameters.new(item.as_json.merge(lot.as_json))
    objs.permit(:barcode, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :brand, :expiry, :description, :brand, :color, :item_code)
  end

  def prescription_params
    # JSON.parse(params[:data])
    params.require(:data).permit!.except(:fullname, :mobilenumber, :email, :patient_org_id)
  end

  def prescription_patient_params
    params.require(:data).permit(:fullname, :mobilenumber, :email)
  end

  def advance_invoice_params
    params.require(:advance_invoice_data).permit(:patient_org_id, :prescription_id, :patient_name, :reason, :advance_amount)
  end
end
