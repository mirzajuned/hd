class Inventory::ItemsController < ApplicationController
  before_action :authorize, :verify_store
  include Inventory::ItemsHelper
  require 'spreadsheet'
  require 'roo'
  layout 'backbone'
  before_action :set_inventory_item, only: [:show, :edit, :update, :disable, :destroy, :get_lots]

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    category_ids = @inventory_store&.category_ids || []
    @categories = Inventory::Category.where(:id.in => category_ids).pluck(:name, :id)
    @category = params[:item_type]
    @stock = params[:stock]
    @description = params[:items]
    @category_id = params[:category_id]
    fetch_items_index
  end

  def bulk_upload_data
    fetch_categories
    fetch_sub_categories
    fetch_dispensing_units
    fetch_tax_groups
  end

  def append_index
    @store_id = params[:store_id]
    @category = params[:item_type]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    fetch_items_index
  end

  def filter_index
    @store_id = params[:store_id]
    @category = params[:item_type]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    fetch_items_index
  end

  def filter_item
    @store_id = params[:store_id]
    @department_id = params[:department_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    category_ids = @inventory_store&.category_ids || []
    @categories = Inventory::Category.where(:id.in => category_ids).pluck(:name, :id)
    @category_id = params[:category_id]
  end

  def show
    @item_histories = Inventory::Audit::History.where(item_id: params[:id]).order_by(created_at: 'desc')
    @current_inventory = '334046963'
    @variant_id = Inventory::Item::Variant.find_by(item_code: @inventory_item.item_code).id
  end

  def new
    @inventory_item = Inventory::Item.new

    @item_category_id = params[:item_category_id]

    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)

    if params[:store_id].present?
      @level = "store"
      @inventory_store = Inventory::Store.find_by(id: params[:store_id])
      options = { :id.in => @inventory_store.category_ids, is_disable: false }
      options = options.merge(stockable: false) if params[:action_from] == 'sale_order'
      @inventory_categories = Inventory::Category.where(options)
    else
      @level = "organisation"
      @inventory_categories = Inventory::Category.where(:organisation_id.in => [current_user.organisation_id], is_disable: false)
    end

    if @inventory_categories.blank?
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Warning', text: 'There is no category linked to this store. Please link atleast one category to create Item.', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
      #to be removed and give notify that category is not linked or created
      # @inventory_categories = Inventory::Category.where(:organisation_id.in => [current_user.organisation_id], is_disable: false)
    end

    @item_category = Inventory::Category.find_by(id: @item_category_id, is_disable: false) || @inventory_categories[0]

    @inventory_sub_categories = Inventory::SubCategory.where(category_id: @item_category.try(:id), is_disable: false)
    @dispensing_units = Inventory::DispensingUnit.where(:id.in => @item_category.try(:dispensing_unit_ids) , is_disable: false)

    @generic_class_categories = GenericClass.all.pluck(:category).uniq&.sort
    @action_from = params[:action_from]
    @vendors = Inventory::Vendor.where(:category_ids.in => [@item_category.id], is_deleted: false)
  end

  def edit
    @inventory_categories = Inventory::Category.where(:organisation_id.in => [current_user.organisation_id], is_disable: false)
    @inventory_sub_categories = Inventory::SubCategory.where(category_id: @inventory_item.try(:category_id), is_disable: false)
    @item_category = Inventory::Category.find_by(id: @inventory_item.try(:category_id), is_disable: false) || @inventory_categories[0]
    @dispensing_units = Inventory::DispensingUnit.where(:id.in => @item_category.try(:dispensing_unit_ids) , is_disable: false)
    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)
    @custom_fields = @inventory_item&.custom_fields
    custom_field_data = @inventory_item_lots.all.pluck(:custom_field_data)
    @generic_class_categories = GenericClass.all.pluck(:category).uniq&.sort
    @cf_data = []
    custom_field_data.each do |cf|
      cf.each do |k, v|
        @cf_data << k if v.present?
      end
    end
     @vendors = Inventory::Vendor.where(:category_ids.in => [@item_category.id], is_deleted: false)
  end

  def check_description
    if params[:from].present? && params[:from] == 'bulk_upload'
      existing = []
      params[:descriptions].uniq.each do |desc|
        inv_item = Inventory::Item.find_by(organisation_id: current_user.organisation_id, description: /#{Regexp.escape(desc.upcase)}$/i, is_disabled: false)
        unless inv_item.try(:to_a).blank?
          existing << desc
        end
      end
      respond_to do |format|
        format.json { render json: {existing: existing} }
      end
    else
      existing_description = params[:existing_description]
      description = params[:inventory_item][:description].to_s.strip.upcase
  
      if existing_description != description
        @inv_item = Inventory::Item.find_by(organisation_id: current_user.organisation_id, description: /#{Regexp.escape(description)}$/i, is_disabled: false)
      end
      respond_to do |format|
        format.json { render json: !@inv_item.try(:to_a).present? }
      end
    end
  end

  def add_custom_field
    @item = Inventory::Item.build
  end

  def create
    @action = params[:action]
    @store_id = params[:inventory_item][:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @category_id = params[:inventory_item][:category_id]
    # description = params[:inventory_item][:description]&.titleize
    item_code = Inventory::ItemsHelper.increment_and_create_item_code(params[:inventory_item][:organisation_id], @category_id)
    # category = params[:inventory_item][:category] == 'intraocular_lens' ? 'intraocular' : params[:inventory_item][:category]
    # category_model_type = category.titleize.camelize.gsub(' ', '::')
    # @inventory_item = "Inventory::Item::#{category_model_type}".constantize.new(inventory_item_category_params(@category))
    @inventory_item = Inventory::Item.new(inventory_item_params)
    @inventory_item.item_code = item_code
    # @inventory_item.description = description
    @inventory_item.reference_id = @inventory_item.id.to_s
    @inventory_item.search = "#{@inventory_item.description} #{@inventory_item.model_no}"
    barcode_id = Inventory::Items::GenerateBarCodeService.call(item_code, current_facility.id)
    @inventory_item.barcode_id = barcode_id.data
    generic_full_names(@inventory_item)
    if @inventory_item.save!
      default_variant = Inventory::Variants::CreateService.default(@inventory_item, 'item_master')
      fetch_items_index
      InventoryJobs::CloneItemJob.perform_later(@inventory_item.id.to_s, default_variant.id.to_s)
      # InventoryJobs::LinkStoreVendorJob.perform_later(@inventory_item.category_id.to_s)
    end
    if params[:inventory_item][:action_from] == 'sale_order'
      @item = Inventory::Item.find_by(id: @inventory_item.id)
      @inventory_order = Invoice::InventoryOrder.build
      @tax_group = TaxGroup.find(@item.tax_group_id)
      @tax_rate_details = @tax_group.tax_rate_details.collect { |tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type) }
      @type = 'non_stockable'
      @item_created_from = 'sale_order'
      render '/invoice/inventory_orders/add_item.js.erb'
      # redirect_to add_item_invoice_inventory_orders_path(@inventory_item.id)
    end
  end

  def disable
    @action = params[:action]
    reference_id = @inventory_item.reference_id
    inventory_items = Inventory::Item.where(reference_id: reference_id)
    inventory_item_stock = inventory_items.pluck(:stock).map(&:to_i).inject(&:+)
    @inventory_store = Inventory::Store.find_by(id: @inventory_item&.store_id)

    if inventory_item_stock == 0
      inventory_items.update_all(is_disabled: true)
      inventory_variants = Inventory::Item::Variant.where(:item_id.in => inventory_items.pluck(:id))
      inventory_variants.update_all(is_disabled: true)
      @category = ['all_item']
      @store_id = @inventory_item.store_id
      fetch_items_index
    else
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Warning', text: 'Cannot Remove Item. Item Stock is still present.', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    end
  end

  def update
    sti_names = ["inventory_item_optical_other", "inventory_item_optical_spectacle", "inventory_item_optical_contact", "inventory_item_optical_frame", "inventory_item_miscellaneous", "inventory_item_consumable", "inventory_item_implant","inventory_item_stockable","inventory_item_asset", "inventory_item_medication", "inventory_item_intraocular", "inventory_item_spectacle", "inventory_item_other", "inventory_item_contact", "inventory_item_frame", "inventory_item"]

    params_inventory_item = params[sti_names.detect{|sti| params.keys.include?(sti)}]
    tax_group_id = params[:inventory_item][:tax_group_id]
    tax_group = TaxGroup.find_by(id: tax_group_id)
    tax_rate = tax_group&.rate
    tax_name = tax_group&.name
    tax_inclusive = params_inventory_item[:tax_inclusive]
    description = params_inventory_item[:description]
    model_no = params_inventory_item[:model_no]
    manufacturer = params_inventory_item[:manufacturer]
    hsn_no = params_inventory_item[:hsn_no]
    brand = params_inventory_item[:brand]
    sub_category_id = params_inventory_item[:sub_category_id]
    sub_category_name = params_inventory_item[:sub_category_name]
    expiry_present = params_inventory_item[:expiry_present].to_bool
    prescription_mandatory = params_inventory_item[:prescription_mandatory]
    dispensing_unit_id = params_inventory_item[:dispensing_unit_id]
    dispensing_unit = params_inventory_item[:dispensing_unit]
    reference_id = @inventory_item.reference_id
    @item_histories = Inventory::Audit::History.where(item_id: params[:id])
    inventory_items = Inventory::Item.where(reference_id: reference_id)
    generic_names = params[:inventory_item][:generic_names_attributes]
    search = "#{description} #{model_no}"
    stockable = params_inventory_item[:stockable]
    pricing_index = params_inventory_item[:pricing_index]
    package_type = params_inventory_item[:package_type]
    sub_package_units = params_inventory_item[:sub_package_units]
    sub_package_type = params_inventory_item[:sub_package_type]
    item_units = params_inventory_item[:item_units]
    item_type = params_inventory_item[:item_type]
    inventory_items.update_all(tax_rate: tax_rate, tax_name: tax_name, tax_group_id: tax_group_id,
                               tax_inclusive: tax_inclusive, description: description, model_no: model_no,
                               hsn_no: hsn_no, manufacturer: manufacturer, brand: brand, 
                               sub_category_id: sub_category_id, expiry_present: expiry_present, 
                               prescription_mandatory: prescription_mandatory, stockable: stockable,
                               dispensing_unit: dispensing_unit, dispensing_unit_id: dispensing_unit_id, 
                               search: search, sub_category_name: sub_category_name, pricing_index: pricing_index,
                               package_type: package_type, sub_package_units: sub_package_units,
                               sub_package_type: sub_package_type, item_units: item_units, item_type: item_type)
    inventory_items.each do |item|
      item.generic_names.delete_all
      new_generic_names = []
      generic_names&.each do |key, generic_name|
        next if generic_name[:name].blank?
        new_generic_names << { name: generic_name[:name], generic_id: generic_name[:generic_id],
                                            quantity: generic_name[:quantity], unit: generic_name[:unit] }
      end
      item.generic_names.create!(new_generic_names)
      generic_full_names(item)
      variants = Inventory::Item::Variant.where(item_id: item.id)
      variants.each do |variant|
        variant[:description] = item.description
        variant[:model_no] = item.model_no
        variant[:search] = "#{item.description} #{item.model_no}"
        variant[:generic_display_name] = item.generic_display_name
        variant[:generic_display_ids] = item.generic_display_ids
        variant.save!
      end
      lots = Inventory::Item::Lot.where(item_id: item.id, :store_id.ne => nil)
      lots.each do |lot|
        sub_store = Inventory::Store.find_by(id: lot.store_id).sub_stores[0]
        lot[:tax_rate] = item.tax_rate
        lot[:tax_name] = item.tax_name
        lot[:tax_group_id] = item.tax_group_id
        lot[:tax_inclusive] = item.tax_inclusive
        lot[:description] = item.description
        lot[:model_no] = item.model_no
        lot[:search] = "#{item.description} #{item.model_no}"
        lot[:generic_display_name] = item.generic_display_name
        lot[:generic_display_ids] = item.generic_display_ids
        if tax_inclusive == 'true'
          unit_taxable_amount = (lot.list_price.to_f * tax_rate.to_f) / (100 + tax_rate.to_f)
          lot[:unit_non_taxable_amount] = lot.list_price.to_f - unit_taxable_amount
          lot[:unit_taxable_amount] = unit_taxable_amount
        else
          lot[:unit_taxable_amount] = (lot.list_price.to_f * tax_rate.to_f) / 100
          lot[:unit_non_taxable_amount] = lot.list_price.to_f
        end
        unless lot.sub_store_id.present?
          lot[:sub_store_id] = sub_store&.id
          lot[:sub_store_name] = sub_store&.name
        end
        lot.save!
      end
    end
    fetch_items_index
  end

  def download_data
    stock = params[:stock]
    category = JSON.parse(params[:item_type]&.join(', '))
    store_id = params[:store_id]
    @data_array = Inventory::Items::DownloadItemService.call(store_id, stock, category)
    @filename = "#{params[:department_name]&.downcase}_master_level_report.xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  def print_items
    @facilityid = current_facility.id
    setting_service = PrintSettingService.new(@facilityid, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    if params[:data] == 'medication'
      @items = Inventory::Item::Medication.where(facility_id: @facilityid, is_deleted: false, 'stock' => { '$gte' => 1 })
      respond_to do |format|
        format.pdf { render template: 'inventory/items/print_stock_item', pdf: 'ItemList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 }, orientation: 'Landscape' }
      end
    elsif params[:data] == 'optical'
      @item1 = Inventory::Item::Optical::Frame.where(facility_id: @facilityid, is_deleted: false, 'stock' => { '$gte' => 1 })
      @item2 = Inventory::Item::Optical::Contact.where(facility_id: @facilityid, is_deleted: false, 'stock' => { '$gte' => 1 })
      @item3 = Inventory::Item::Optical::Other.where(facility_id: @facilityid, is_deleted: false, 'stock' => { '$gte' => 1 })
      @items = @item1 + @item2 + @item3
      respond_to do |format|
        format.pdf { render template: 'inventory/items/print_optical_item', pdf: 'ItemList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 }, orientation: 'Landscape' }
      end
    elsif params[:data] == 'out_stock'
      @items = Inventory::Item.where(facility_id: current_facility.id, stock: 0, is_deleted: false)
      respond_to do |format|
        format.pdf { render template: 'inventory/items/print_outofstock_item', pdf: 'ItemList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 }, orientation: 'Landscape' }
      end
    end
  end

  # def update
  #   @current_inventory = 'central'
  #   @current_inventory = '334046963'
  #   update_type = params[:update_type]
  #   if update_type == 'lots'
  #     self_batched = false # flag to check later
  #     facility_id = current_facility.id
  #     category = params[:inventory_item][:category]
  #     if params[:checkoutable] == true
  #       if params[:batch_no]
  #         if params[:batch_no].empty?
  #           batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(@inventory_item.id, facility_id)
  #           self_batched = true
  #         else
  #           batch_no = params[:batch_no]
  #         end
  #       end

  #       existing_lot = @inventory_item.lots.find_by(batch_no: batch_no)
  #       if existing_lot
  #         existing_lot.stock += params[:stock].to_i
  #         existing_lot.save!
  #         @inventory_item.stock = @inventory_item.calculate_stock
  #         if @inventory_item.save!
  #           respond_to do |format|
  #             format.json { render action: 'show' }
  #           end
  #         end

  #       else

  #         lot = @inventory_item.lots.new(stock_update_params)
  #         lot.batch_no = batch_no
  #         lot.self_batched = self_batched
  #         lot.stock = params[:stock_unit] if @inventory_item.category == ('medication' || 'consumable')
  #         if lot.save!
  #           capacity = 0
  #           @inventory_item.lots.where(is_deleted: false).each { |lot| capacity += lot.stock }
  #           @inventory_item.inventory_capacity = capacity
  #           @inventory_item.stock = @inventory_item.calculate_stock

  #           respond_to do |format|
  #             format.json { render action: 'show' } if @inventory_item.save!
  #           end
  #         end
  #       end
  #     else
  #       @inventory_item.maintainance_due = params[:maintainance_due]
  #       @inventory_item.maintained_on = params[:maintained_on]
  #       @inventory_item.condition = params[:condition]
  #       respond_to do |format|
  #         format.json { render action: 'show' } if @inventory_item.save!
  #       end
  #     end
  #   else
  #     respond_to do |format|
  #       if @inventory_item.category == 'optical'
  #         if @inventory_item.update(inventory_item_category_update_params(@inventory_item.item_type))
  #           format.js { render 'show' }
  #         else
  #           format.js { render action: 'edit' }
  #           # format.json { render json: @inventory_item_lot.errors, status: :unprocessable_entity }
  #         end
  #       else
  #         if @inventory_item.update(inventory_item_category_update_params(@inventory_item.category))
  #           format.js { render 'show' }
  #         else
  #           format.js { render action: 'edit' }
  #           # format.json { render json: @inventory_item_lot.errors, status: :unprocessable_entity }
  #         end
  #       end
  #     end

  #   end

  # end

  def destroy
    # fail
    facility_id = current_facility.id

    if @inventory_item.update(is_deleted: true)
      @inventory_department_request_logs = Inventory::Department::RequestLog.where(facility_id: facility_id, status: -1)
      @items = Inventory::Item.where(facility_id: facility_id, is_deleted: false).limit(20)
      @allCount = @items.count
      @title = 'Central Inventory'
      @out_stock_count = @items.where(stock: 0).count
      @inventory_item_cart_count = @items.where(in_cart: true).count
    end

    respond_to do |format|
      format.js { render action: 'destroy' }
    end
  end

  def request_logs
    facility_id = current_facility.id
    @request_logs = Inventory::Department::RequestLog.where(facility_id: facility_id, status: -1)
    respond_to do |format|
      format.json { render json: @request_logs }
    end
  end

  def remove_from_cart
    @facilityid = current_facility.id
    if params[:item_id] == 'all'
      @inventory_item = Inventory::Item.where(facility_id: @facilityid, is_deleted: false, in_cart: true)
      @inventory_item.update_all(in_cart: params[:in_cart]) # true or false (boolean)
    else
      @inventory_item = Inventory::Item.find(params[:item_id])
      @inventory_item.update(in_cart: params[:in_cart]) # true or false (boolean)
    end

    @inventory_item_cart = Inventory::Item.where(in_cart: true, is_deleted: false, facility_id: @facilityid)
    @inventory_item_cart_count = @inventory_item_cart.count

    @items = Inventory::Item.where(facility_id: @facilityid, is_deleted: false).limit(20)
    # @inventory_item_cart_count = @items.where(in_cart: true).count
    # @allCount = @items.count
    # @out_stock_count = @items.where(stock: 0).count
    @title = 'Central Inventory'

    respond_to do |format|
      format.js {}
    end
  end

  def update_cart
    @facilityid = current_facility.id
    @inventory_item = Inventory::Item.find(params[:item_id])
    @inventory_item.update(in_cart: params[:in_cart]) # true or false (boolean)
    @inventory_item_cart_count = Inventory::Item.where(in_cart: true, is_deleted: false, facility_id: @facilityid, 'stock' => { '$gte' => 1 }).count
    respond_to do |format|
      format.json {}
    end
  end

  def show_cart
    @facilityid = current_facility.id
    @inventory_item_cart = Inventory::Item.where(in_cart: true, is_deleted: false, facility_id: @facilityid)
    respond_to do |format|
      format.js { render action: 'show_cart' }
    end
  end

  def show_checkout_cart
    @facilityid = current_facility.id
    @items = params[:items]
    @inventory_departments = Inventory::Department.where(facility_id: @facilityid)

    @inventory_request_department = params[:department]

    if @inventory_request_department.present?
      @inventory_departments = @inventory_departments.where(department_id: @inventory_request_department)
    end

    @department_array = @inventory_departments.reject { |s| s.department_id == '334046963' }.map { |s| [s.name, s.department_id] }

    @current_inventory = '334046963'

    respond_to do |format|
      format.js { render action: 'show_checkout_cart' }
    end
  end

  def log_checkout # Transfers item from Central to other departments
    facility_id = current_facility.id
    department = params[:department]
    # items = eval(params[:items])
    items = JSON.parse(params[:items].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
    @item_id = items.keys
    @item_category = Inventory::Item.where(:id.in => @item_id).pluck(:category)

    @inventory_checkout_log = Inventory::CheckoutLog.new(department_id: department, facility_id: facility_id, recipient: params[:recipient], authorized_by: params[:authorized_by])
    if (@item_category.include?('medication') || @item_category.include?('consumable')) && @item_category.include?('optical')
      respond_to do |format|
        message = @item_category.join(', ').titleize
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'cannot checkout #{message} together', type: 'warning' }); notice.get().click(function(){ notice.remove() });" }
      end
    elsif (department == '284748001') && @item_category.include?('optical')
      respond_to do |format|
        message = @item_category.join(', ').titleize
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'cannot checkout #{message} items in Pharmacy', type: 'warning' }); notice.get().click(function(){ notice.remove() });" }
      end
    elsif (department == '50121007') && (@item_category.include?('medication') || @item_category.include?('consumable'))
      respond_to do |format|
        message = @item_category.join(', ').titleize
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'cannot checkout #{message} items in Optical', type: 'warning' }); notice.get().click(function(){ notice.remove() });" }
      end
    else
      if @inventory_checkout_log.save!
        items.each do |key, value|
          inventory_item = Inventory::Item.find_by(facility_id: facility_id, id: key)

          # Rails.logger.info("===============================#{inventory_item.as_json}")

          next if value.to_i > inventory_item.stock

          lots = inventory_item.lots.where(empty: false, is_deleted: false).order('expiry asc')

          counter = 1
          quantity = value.to_i
          lots.each do |lot|
            counter += 1
            if lot.stock >= quantity
              # Quantiy is less than stocks in the Lot
              log_item = @inventory_checkout_log.items.new(params_log_checkout_item(inventory_item, lot))
              log_item.quantity = quantity
              if inventory_item.category == 'optical'
                d_item = create_or_update_departmental_item(facility_id, inventory_item.category, inventory_item, department, lot, quantity, inventory_item.item_type)
              else
                d_item = create_or_update_departmental_item(facility_id, inventory_item.category, inventory_item, department, lot, quantity)
              end
              # if inventory_item.item_type
              #   d_item = create_or_update_optical_item(facility_id, inventory_item.category, inventory_item.item_type, inventory_item, department, lot, quantity)
              # else
              #   d_item = create_or_update_departmental_item(facility_id, inventory_item.category, inventory_item, department, lot, quantity)
              # end
              if d_item.save!
                if log_item.save!
                  lot.stock -= quantity
                  if lot.save!
                    inventory_item.checkout_count = inventory_item.checkout_count + 1
                    inventory_item.stock -= quantity; inventory_item.save!
                  end
                end
              end
              break
            else
              # Quantiy is greater than stocks in the Lot
              quantity -= lot.stock
              log_item = @inventory_checkout_log.items.new(params_log_checkout_item(inventory_item, lot))
              log_item.quantity = lot.stock
              d_item = create_or_update_departmental_item(facility_id, inventory_item.category, inventory_item, department, lot, lot.stock)
              if d_item.save!
                if log_item.save!
                  inventory_item.stock -= lot.stock; inventory_item.save!
                  lot.update_attributes(stock: 0, empty: true)
                  if lot.save!
                    # inventory_item.stock -= lot.stock; inventory_item.save!
                  end
                end
              end
              # log_item.save
            end
          end
        end

        facility_id = current_facility.id
        @items = Inventory::Item.where(facility_id: facility_id, is_deleted: false)
        @inventory_item = @items.where(in_cart: true)
        @inventory_item.update_all(in_cart: false)
        @inventory_item_cart_count = 0
        @title = 'Central Inventory'

        @inventory_department_request_logs = Inventory::Department::RequestLog.where(facility_id: facility_id, status: -1)
        @allCount = @items.count # After saving the item counts going to be increased
        @out_stock_count = @items.where(stock: 0).count

        respond_to do |format|
          format.js
        end
      end
    end
  end

  def create_or_update_departmental_item(_facility_id, category, item, department, lot, quantity, *extras) # in extras we send item_type for opticals
    departmental_item = Inventory::Department::Item.where(department_id: department).find_by(inventory_item_id: item.id)
    if departmental_item
      departmental_item_lot = departmental_item.lots.find_by(batch_no: lot.batch_no)
      if departmental_item_lot
        departmental_item_lot.stock += quantity
        departmental_item_lot.empty = false
        if departmental_item_lot.save!
          departmental_item.stock += quantity
          departmental_item if departmental_item.save!
        end
      else
        departmental_item_lot = departmental_item.lots.new(lot.attributes.except('_id', 'created_at', 'item_id', 'updated_at', 'stock'))

        departmental_item_lot.item_id = departmental_item.id
        departmental_item_lot.stock = quantity
        p departmental_item_lot.stock

        if departmental_item_lot.save!

          departmental_item.stock += departmental_item_lot.stock
          departmental_item if departmental_item.save!
        end
      end
    else
      case category
      when 'medication'
        departmental_item = Inventory::Department::Item::Medication.new(item.attributes.except('_id', '_type', 'created_at', 'updated_at', 'in_cart', 'is_deleted'))
      when 'consumable'
        departmental_item = Inventory::Department::Item::Consumable.new(item.attributes.except('_id', '_type', 'created_at', 'updated_at', 'in_cart', 'is_deleted'))
      when 'implant'
        departmental_item = Inventory::Department::Item::Implant.new(item.attributes.except('_id', '_type', 'created_at', 'updated_at', 'in_cart', 'is_deleted'))
      when 'stockable'
        departmental_item = Inventory::Department::Item::Stockable.new(item.attributes.except('_id', '_type', 'created_at', 'updated_at', 'in_cart', 'is_deleted'))
      when 'miscellaneous'
        departmental_item = Inventory::Department::Item::Miscellaneous.new(item.attributes.except('_id', '_type', 'created_at', 'updated_at', 'in_cart', 'is_deleted'))
      when 'optical'
        case extras[0]
        when 'frame'

          departmental_item = Inventory::Department::Item::Optical::Frame.new(item.attributes.except('_id', '_type', 'created_at', 'updated_at', 'in_cart', 'is_deleted'))
        when 'contact'
          departmental_item = Inventory::Department::Item::Optical::Contact.new(item.attributes.except('_id', '_type', 'created_at', 'updated_at', 'in_cart', 'is_deleted'))
        when 'other'
          departmental_item = Inventory::Department::Item::Optical::Other.new(item.attributes.except('_id', '_type', 'created_at', 'updated_at', 'in_cart', 'is_deleted'))
        end
      end

      departmental_item.department_id = department
      departmental_item.inventory_item_id = item.id
      # d_item.stock = lot.stock
      if departmental_item.save!
        departmental_item_lot = departmental_item.lots.new(lot.attributes.except('_id', 'created_at', 'item_id', 'updated_at', 'stock'))
        departmental_item_lot.item_id = departmental_item.id
        departmental_item_lot.stock = quantity

        if departmental_item_lot.save!
          departmental_item.update_attributes(stock: departmental_item.calculate_stock)
          departmental_item
        end
      end
    end
  end

  def get_category_class(main_category, category)
    case main_category
    when 'Medication'
      category_class = Inventory::Item::Medication
    when 'Consumable'
      category_class = Inventory::Item::Consumable
    when 'Implant'
      category_class = Inventory::Item::Implant
    when 'Stockable'
      category_class = Inventory::Item::Stockable
    when 'Miscellaneous'
      category_class = Inventory::Item::Miscellaneous
    when 'Asset'
      category_class = Inventory::Item::Asset
    when 'Optical'
      case category
      when 'Frame'
        category_class = Inventory::Item::Optical::Frame
      when 'Contact'
        category_class = Inventory::Item::Optical::Contact
      when 'Other'
        category_class = Inventory::Item::Optical::Other
      else
        category_class = Inventory::Item::Optical::Other
      end
    else
      category_class = Inventory::Item
    end
    category_class
  end

  def download_excel_sheet
    send_file(
      "#{Rails.root}/public/HG-SampleInventory.xls",
      filename: 'HG-SampleInventory.xls',
      type: 'application/xls'
    )
  end

  def upload_print_settings
    department = Inventory::Department.find_by(facility_id: current_facility.id, department_id: params[:department_id])
    @inventory_department = Inventory::Department.create(username: params[:username], shop_address: params[:shop_address], asset_path: params[:print_out_logo] || department.asset_path, facility_id: current_facility.id, department_id: params[:department_id], display_name: department.display_name, name: department.name, shop_name: params[:shop_name], dl_number: params[:dl_number], gst: params[:gst], email: params[:email], contact: params[:contact])
    department.delete
    respond_to do |format|
      format.js
    end
  end

  def upload_data
    uploaded_excel = params[:items_bulk_data][:document]
    fetch_tax_groups
    fetch_categories
    fetch_sub_categories
    fetch_dispensing_units
    fetch_generic_class_categories
    fetch_item_types
    fetch_package_types
    fetch_sub_package_types
    @items = []
    @error = nil
    begin
      excel_file = Roo::Spreadsheet.open(uploaded_excel.tempfile)
      excel_file.sheets.each do |worksheet|
        sheet = excel_file.sheet(worksheet)
        (2..sheet.last_row).each do |row_index|
          row = sheet.row(row_index)
          hsn_required = current_organisation['inventory_hsn_code_required']
          next if row[0].blank? || row[1].blank? || (hsn_required && row[2].blank?) || row[8].blank?
          category = row[0].strip
          category_record = @inventory_categories.find_by(name: /^#{category}$/i)
          next if category_record.blank?
          category_type = category_record&.type&.capitalize
          category_class = get_category_class(category_type, category.capitalize)
          item = category_class.new(prepare_json_data(row, category_type))
          if category_record.default_possible_variants.present?
            category_record.default_possible_variants.each do |pv|
              item.custom_fields.build(name: pv[:name], value: pv[:value])        
            end
          else
            item.custom_fields.build
          end
          item.generic_names.build
          @items << item
        end
      end
    rescue => e
      @error = "Invalid File Format please use the sample filen to upload data."
    end
    respond_to do |format|
      format.js { render 'edit_multiple.js.erb' }
    end
  end

  def update_multiple
    inventory_items = params[:inventory_item].to_unsafe_h.values
    CreateMultipleItemJob.perform_later(inventory_items, current_facility.id.to_s)
  end

  def add_possible_variant
    @item = Inventory::Item.new
    @index = params[:index]
    if params[:category_id].present?
      @category = Inventory::Category.find_by(id: params[:category_id])    
        if @category.default_possible_variants.present?
          @category.default_possible_variants.each do |pv|
            @item.custom_fields.build(name: pv[:name], value: pv[:value])        
          end
        else
          @item.custom_fields.build
        end
    else
      @item.custom_fields.build
    end
    respond_to do |format|
      format.js
    end
  end

  def add_generic_composition
    @item = Inventory::Item.new
    @item.generic_names.build
    @index = params[:index]
    respond_to do |format|
      format.js
    end
  end

  def upload_excel_sheet
    facility_id = current_facility.id
    uploaded_excel = params[:uploaded_excel]
    begin
      Spreadsheet.client_encoding = 'UTF-8'
      excel_file = Spreadsheet.open uploaded_excel.tempfile
      excel_file.worksheets.each do |worksheet|
        category = worksheet.name.downcase
        if category.index('medication')
          worksheet.each 1 do |row|
            next if row[1].nil?

            item_code = Inventory::ItemsHelper.increment_and_create_item_code(facility_id, category)
            sub_units = if row[6].nil?
                          1
                        else
                          row[6]
                        end

            barcode = if row[3].is_a?(Numeric)
                        row[3].to_i.to_s
                      else
                        row[3].to_s
                      end

            stock = row[8].to_i * sub_units
            item = Inventory::Item::Medication.new(facility_id: facility_id, item_code: item_code, category: category, description: row[1], dispensing_unit: row[2], barcode: barcode, dosage: row[5], sub_units: sub_units, threshold: row[7], inventory_capacity: stock, manufacturer: row[10], stock: stock)

            vendor = row[9]
            price = (row[11].to_f / sub_units).round(2)
            mark_up = row[12].to_f
            mrp = (row[13].to_f / sub_units).round(2)
            list_price = (row[14].to_f / sub_units).round(2)
            expiry = row[15]
            next unless item.save!

            self_batched = false
            if row[4].nil? || row[4].to_s.empty?
              batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(item.id, facility_id)
              self_batched = true
            else
              batch_no = row[4].to_s
            end

            print "Item is saved as #{category}"
            lot = item.lots.new(batch_no: batch_no, vendor: vendor, price: price, mark_up: mark_up, mrp: mrp, list_price: list_price, expiry: expiry, stock: stock, self_batched: self_batched)
            lot.save!
            create_vendor(vendor, facility_id)
          end
        elsif category.index('consumable')
          # puts "Category is Consumable"
          worksheet.each 1 do |row|
            next if row[1].nil?

            item_code = Inventory::ItemsHelper.increment_and_create_item_code(facility_id, category)
            sub_units = if row[4].nil?
                          1
                        else
                          row[4]
                        end

            barcode = if row[2].is_a?(Numeric)
                        row[2].to_i.to_s
                      else
                        row[2].to_s
                      end

            stock = row[5].to_i * sub_units
            item = Inventory::Item::Consumable.new(facility_id: facility_id, item_code: item_code, category: category, description: row[1], barcode: barcode, threshold: (stock * 0.3).to_i, inventory_capacity: stock, manufacturer: row[6], sub_units: sub_units, stock: stock)

            vendor = row[6]
            manufacturer = row[7]
            price = (row[8] / sub_units).round(2)
            mark_up = row[9]
            mrp = (row[10] / sub_units).round(2)
            list_price = (row[11] / sub_units).round(2)
            expiry = row[12]

            next unless item.save!

            self_batched = false
            if row[3].nil? || row[3].to_s.empty?
              batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(item.id, facility_id)
              self_batched = true
            else
              batch_no = row[3].to_s
            end
            print "Item is saved as #{category}"
            lot = item.lots.new(batch_no: batch_no, vendor: vendor, price: price, mark_up: mark_up, mrp: mrp, list_price: list_price, expiry: expiry, stock: stock, self_batched: self_batched)
            lot.save!
            create_vendor(vendor, facility_id)
          end
        elsif category.index('implant')
          # puts "Category is Implant"
          worksheet.each 1 do |row|
            next if row[1].nil?

            item_code = Inventory::ItemsHelper.increment_and_create_item_code(facility_id, category)

            barcode = if row[2].is_a?(Numeric)
                        row[2].to_i.to_s
                      else
                        row[2].to_s
                      end

            item = Inventory::Item::Implant.new(facility_id: facility_id, item_code: item_code, category: category, description: row[1], barcode: barcode, threshold: (row[4] * 0.3).to_i, inventory_capacity: row[4].to_i, manufacturer: row[6], stock: row[4].to_i)

            vendor = row[5]
            price = row[7]
            mark_up = row[8]
            mrp = row[9]
            list_price = row[10]
            expiry = row[11]
            warranty_expiry = row[12]

            next unless item.save!

            self_batched = false
            if row[3].nil? || row[3].to_s.empty?
              batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(item.id, facility_id)
              self_batched = true
            else
              batch_no = row[3].to_s
            end
            print "Item is saved as #{category}"
            lot = item.lots.new(batch_no: batch_no, vendor: vendor, price: price, mark_up: mark_up, mrp: mrp, list_price: list_price, expiry: expiry, warranty_expiry: warranty_expiry, stock: row[4], self_batched: self_batched)
            lot.save!
            create_vendor(vendor, facility_id)
          end
        elsif category.index('stockable')
          worksheet.each 1 do |row|
            next if row[1].nil?

            item_code = Inventory::ItemsHelper.increment_and_create_item_code(facility_id, category)

            barcode = if row[2].is_a?(Numeric)
                        row[2].to_i.to_s
                      else
                        row[2].to_s
                      end

            item = Inventory::Item::Stockable.new(facility_id: facility_id, item_code: item_code, category: category, description: row[1], barcode: barcode, manufacturer: row[6], stock: row[4].to_i)

            vendor = row[5]
            price = row[7]
            expiry = row[8]
            condition = row[9]

            next unless item.save!

            self_batched = false
            if row[3].nil? || row[3].to_s.empty?
              batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(item.id, facility_id)
              self_batched = true
            else
              batch_no = row[3].to_s
            end
            print "Item is saved as #{category}"

            lot = item.lots.new(batch_no: batch_no, vendor: vendor, price: price, expiry: expiry, stock: row[4], self_batched: self_batched)
            lot.save!
            create_vendor(vendor, facility_id)
          end
        elsif category.index('asset')
          worksheet.each 1 do |row|
            next if row[1].nil?

            item_code = Inventory::ItemsHelper.increment_and_create_item_code(facility_id, category)

            barcode = if row[2].is_a?(Numeric)
                        row[2].to_i.to_s
                      else
                        row[2].to_s
                      end

            item = Inventory::Item::Asset.new(item_code: item_code, facility_id: facility_id, category: category, description: row[1], barcode: barcode, stock: row[3], vendor: row[5], manufacturer: row[6], price: row[7], expiry: row[8], warranty_expiry: row[9], maintained_on: row[10], maintainance_due: row[11], condition: row[12], checkoutable: row[13])
            next unless item.save!

            self_batched = false
            if row[4].nil? || row[4].to_s.empty?
              batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(item.id, facility_id)
              self_batched = true
            else
              batch_no = row[4].to_s
            end
            item.batch_no = batch_no
            self_batched = self_batched
            item.save!
            print "Item is saved as #{category}"
          end
        elsif category.index('miscellaneous')
          # puts "Category is Miscellaneous"
          worksheet.each 1 do |row|
            next if row[1].nil?

            item_code = Inventory::ItemsHelper.increment_and_create_item_code(facility_id, category)

            barcode = if row[2].is_a?(Numeric)
                        row[2].to_i.to_s
                      else
                        row[2].to_s
                      end

            item = Inventory::Item::Miscellaneous.new(item_code: item_code, facility_id: facility_id, category: category, description: row[1], barcode: barcode, threshold: (row[4] * 0.3).to_i, manufacturer: row[6], inventory_capacity: row[4], stock: row[4].to_i)

            vendor = row[5]
            manufacturer = row[6]
            price = row[7]
            expiry = row[8]
            next unless item.save!

            self_batched = false
            if row[3].nil? || row[3].to_s.empty?
              batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(item.id, facility_id)
              self_batched = true
            else
              batch_no = row[3].to_s
            end
            print "Item is saved as #{category}"
            lot = item.lots.new(batch_no: batch_no, vendor: vendor, price: price, expiry: expiry, stock: row[4], self_batched: self_batched)
            lot.save!
            create_vendor(vendor, facility_id)
          end
        elsif category.index('optical')
          worksheet.each 1 do |row|
            next if row[1].nil?

            # puts "category is #{category}"
            item_code = Inventory::ItemsHelper.increment_and_create_item_code(facility_id, category)
            if category.index('frame')
              # puts "category is Optical & type is frame"

              barcode = if row[3].is_a?(Numeric)
                          row[3].to_i.to_s
                        else
                          row[3].to_s
                        end

              item = Inventory::Item::Optical::Frame.new(item_code: item_code, facility_id: facility_id, category: 'optical', description: row[1], model_no: row[2], barcode: barcode, manufacturer: row[4], brand: row[5], color: row[6], frame_type: row[7], frame_material: row[8], gender: row[9], pricing_index: row[10], stock: row[11].to_i, item_type: 'frame', reference_no: row[18])
              vendor = row[12]
              price = row[13].to_f
              mark_up = row[14].to_f
              mrp = row[15].to_f
              list_price = row[16]
              expiry = row[17]
              if item.save!
                batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(item.id, facility_id)
                self_batched = true

                print "Item saed as #{category}"
                lot = item.lots.new(batch_no: batch_no, vendor: vendor, price: price, mrp: mrp, mark_up: mark_up, list_price: list_price, expiry: Date.current, stock: row[11].to_i)
                lot.save!
                create_vendor(vendor, facility_id)
              end
            elsif category.index('contact')
              # puts "category is Optical & type is contact"

              barcode = if row[3].is_a?(Numeric)
                          row[3].to_i.to_s
                        else
                          row[3].to_s
                        end

              item = Inventory::Item::Optical::Contact.new(item_code: item_code, facility_id: facility_id, category: 'optical', description: row[1], model_no: row[2], barcode: barcode, manufacturer: row[4], brand: row[5], color: row[6], pricing_index: row[7], replacement: row[8], wearing_period: row[9], power: row[10], stock: row[11].to_i, material: row[18], item_type: 'contact', contact_type: row[19], gender: row[20])
              vendor = row[12]
              # batch_no = row[13]
              price = row[13]
              mark_up = row[14]
              mrp = row[15]
              list_price = row[16]
              expiry = row[17]

              if item.save!

                batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(item.id, facility_id)
                self_batched = true

                print "item svad as #{category}"
                lot = item.lots.new(batch_no: batch_no, vendor: vendor, price: price, mrp: mrp, mark_up: mark_up, list_price: list_price, expiry: expiry, stock: row[11].to_i)
                lot.save!
                create_vendor(vendor, facility_id)
              end
            elsif category.index('other')
              # puts "category is Optical & type is other"

              barcode = if row[2].is_a?(Numeric)
                          row[2].to_i.to_s
                        else
                          row[2].to_s
                        end

              item = Inventory::Item::Optical::Other.new(item_code: item_code, facility_id: facility_id, category: 'optical', description: row[1], barcode: barcode, manufacturer: row[5], stock: row[3].to_i, item_type: 'other')
              vendor = row[4]
              # batch_no = row[13]
              price = row[6]
              mrp = row[7]
              mark_up = row[8]
              list_price = row[9]
              expiry = row[10]

              if item.save!
                # self_batched = false
                # if row[3].nil? or row[3].to_s.empty?
                batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(item.id, facility_id)
                self_batched = true
                # else
                #   batch_no = row[3].to_s
                # end

                print "item svad as #{category}"
                lot = item.lots.new(batch_no: batch_no, vendor: vendor, price: price, mrp: mrp, mark_up: mark_up, list_price: list_price, expiry: expiry, stock: row[3].to_i)
                lot.save!
                create_vendor(vendor, facility_id)
              end
            end
          end
        end
      end
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Success', text: 'Successfully added items. Please REFRESH the page.', type: 'success' }); notice.get().click(function(){ notice.remove() });" }
      end
      # puts "Not resucing error"
    rescue Ole::Storage::FormatError
      # puts "Rescuing error"
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Error', text: 'Please upload only <strong>*.xls</strong> files.', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
      # respond_to do |format|
      #   format.js { render js: "notice = new PNotify({ title: 'Error', text: Please upload <strong>xls</strong> format only.', type: 'error' }); notice.get().click(function(){ notice.remote() });" }
      # end
      # # raise
    end
  end

  def get_lots
    # p params
    @inventory_item = Inventory::Item.find(params[:id])
    lots = @inventory_item.lots.where(is_deleted: false).pluck('batch_no')
    render json: lots.as_json
  end

  def get_sub_categories
    @inventory_sub_categories = Inventory::SubCategory.where(:category_id => params[:category_id], is_disable: false)
    @index = params[:index].to_i
    respond_to do |format|
      format.js
    end
  end

  def get_lots_info
    request_type = params[:request_type]
    if request_type == 'individual'
      # lot = Inventory::Item::Lot.find_by(batch_no: params[:batch_no])
      @inventory_item = Inventory::Item.find(params[:id])
      lot = @inventory_item.lots.find_by(batch_no: params[:batch_no])
      render json: lot.as_json
    elsif request_type == 'all'
      @inventory_item = Inventory::Item.find(params[:item_id])
      lots = @inventory_item.lots.where(is_deleted: false)
      render json: lots.as_json
    end
  end

  def get_vendors
    facility_id = current_facility.id
    vendors = Inventory::Vendor.not.where(name: nil).where(facility_id: facility_id).distinct(:name)
    render json: vendors.as_json
  end

  def get_manufacturers
    facility_id = current_facility.id
    manufacturers = Inventory::Item.not.where(manufacturer: nil).where(facility_id: facility_id).distinct(:manufacturer)
    render json: manufacturers.as_json
  end

  def dashboard
    facility_id = current_facility.id
    @department_logs = Invoice.where(_type: 'Invoice::Inventories::Department::PharmacyInvoice', facility_id: facility_id, :created_at.gte => Time.current - (10 * 86400), :created_at.lt => Time.current)
    @pharmacy_logs = Invoice.where(_type: 'Invoice::Inventories::DepartmentInvoice', facility_id: facility_id, :created_at.gte => Time.current - (10 * 86400), :created_at.lt => Time.current)
    @optical_logs = Invoice.where(_type: 'Invoice::Inventories::Department::OpticalInvoice', facility_id: facility_id, :created_at.gte => Time.current - (10 * 86400), :created_at.lt => Time.current)
    @central_logs = Inventory::CheckoutLog.where(facility_id: facility_id, created_at: Time.current - (10 * 86400), :created_at.lt => Time.current)

    respond_to do |format|
      format.json { render json: { logs: { central_logs: @central_logs, department_logs: @department_logs, pharmacy_logs: @pharmacy_logs, optical_logs: @optical_logs } } }
    end
  end

  def download_bulk_upload_data
    @inventory_categories = Inventory::Category.where(:id.in => params[:download_bulk_data][:category_id])
    
    @dispensing_units = Inventory::DispensingUnit.where(:id.in => params[:download_bulk_data][:dispensing_unit_id], is_disable: false)
    
    @tax_groups = TaxGroup.where(:id.in => params[:download_bulk_data][:tax_group_id])
                          .order(created_at: :desc)
    @item_types = params[:download_bulk_data][:item_type]
    @package_types = params[:download_bulk_data][:package_type]
    @sub_package_types = params[:download_bulk_data][:sub_package_type]
    @item = Inventory::Item.new(category: @inventory_categories.first&.name, dispensing_unit_name: @dispensing_units.first&.name, tax_rate: @tax_groups.first&.name)
    respond_to do |format|
      format.xlsx {
        response.headers[
          'Content-Disposition'
        ] = "attachment; filename=items_#{Date.current.strftime('%Y%m%d')}_#{Time.current.strftime('%H%M%S')}.xlsx"
      }
    end
  end

  def get_dispensing_units
    @from = params[:from]
    @index = params[:index]
    @selected = params[:selected]
    @inventory_categories = Inventory::Category.where(:id.in => params[:category_ids])
    dispensing_unit_ids = @inventory_categories.pluck(:dispensing_unit_ids).flatten 
    @dispensing_units = Inventory::DispensingUnit.where(:id.in => dispensing_unit_ids, is_disable: false)
  end

  private

  def fetch_package_types
    @package_types = ["Box", "Pack", "Ampule", "Case", "Dose Pack", "Bottle, Plastic", "Blister Pack", "Package", "Not Stated", "Packet","Supersack", "Tube", "Strip", "Pair"]
  end

  def fetch_sub_package_types
    @sub_package_types = ['Number','Strip','Ampule','Applicator','Bag','Blister Pack','Bottle, with Applicator','Bottle, Dispensing','Bottle, Dropper','Bottle, Glass','Bottle, Plastic','Bottle, Pump','Bottle, Spray','Bottle, Unit-Dose','Box','Pack','Box, Unit-Dose','Can','Canister', 'Carton','Cartridge','Case','Cello Pack''Container','Cup','Cup, Unit-Dose','Cylinder','Dewar','DialPack','Dose Pack','Drum','Inhaler','Inhaler, Refill','Jar','Jug','Kit','Not Stated','Package','Package, Combination','Packet','Pouch','Supersack','Syringe','Syringe, Glass','Syringe, Plastic','Tambinder','Tray','Tube','Tube, With Applicator','Vial','Vial, Dispensing','Vial, Glass','Vial, Multi-Dose', 'Vial, Patent Delivery System','Vial, Pharmacy Bulk Package','Vial, Piggyback', 'Vial, Plastic', 'Vial, Single-Dose', 'Vial, Single-Use','Pair']
  end

  def fetch_item_types
    @item_types = ['Number','Ampule','Applicator','Bottle, with Applicator','Bottle, Dispensing','Bottle, Dropper','Bottle, Glass','Bottle, Plastic','Bottle, Pump','Bottle, Spray','Bottle, Unit-Dose','Box','Pack','Box, Unit-Dose','Can','Canister','Carton','Cartridge','Case','Cello Pack','Container','Cup','Cup, Unit-Dose','Cylinder','Dewar','DialPack','Dose Pack','Drum','Inhaler','Inhaler, Refill','Jar','Jug','Not Stated','Syringe','Syringe, Glass','Syringe, Plastic','Tambinder','Tray','Tube','Tube, With Applicator','Vial','Vial, Dispensing','Vial, Glass','Vial, Multi-Dose','Vial, Patent Delivery System','Vial, Plastic','Vial, Single-Dose','Vial, Single-Use','Pair']
  end

  def prepare_json_data(row, category_type)
    facility_id = current_facility.id
    category = row[0].strip
    category_id = @inventory_categories.find_by(name: /^#{category}$/i)&.id
    description = row[1]
    hsn = row[2]
    brand = row[3]
    manufacturer = row[4]
    model_no = category_type == "Optical" ? row[5] : ""
    price_range = row[6]
    tax_inclusive = row[7] == "Yes"
    tax_rate_object = @tax_groups.find_by(name: /^#{row[8]}$/i)
    tax_group_id = tax_rate_object&.id
    tax_name = tax_rate_object&.name
    unit_level = row[9] == "Yes"
    expiry_present = row[10] == "Yes"
    pres_mandatory = row[11] == "Yes"
    stockable = row[12] == "Yes"
    dispensing_unit = row[13]
    dispensing_unit_id = @dispensing_units.find_by(name: /^#{dispensing_unit}$/i)&.id
    package_type = @package_types.find{|pc| pc.gsub(',', '').downcase == row[14]&.downcase }
    sub_package_units = row[15]
    sub_package_type = @sub_package_types.find{|pc| pc.gsub(',', '').downcase == row[16]&.downcase }
    item_units = row[17]
    item_type = @item_types.find{|pc| pc.gsub(',', '').downcase == row[18]&.downcase }
    fixed_threshold = row[19] == "Yes"
    threshold_value = row[20]
    threshold = row[21].is_a?(Float) ? row[21]*100 : row[21]&.gsub("%","")&.to_f || 30.0

    { facility_id: facility_id, category: category, category_id: category_id, category_name: category, hsn_no: hsn,
      description: description, brand: brand, manufacturer: manufacturer, model_no: model_no, pricing_index: price_range,
      tax_inclusive: tax_inclusive, tax_rate: tax_rate_object&.rate, tax_name: tax_name, tax_group_id: tax_group_id, unit_level: unit_level,
      expiry_present: expiry_present, prescription_mandatory: pres_mandatory, dispensing_unit: dispensing_unit,
      dispensing_unit_id: dispensing_unit_id, dispensing_unit_name: dispensing_unit, package_type: package_type, sub_package_units: sub_package_units,
      sub_package_type: sub_package_type, item_units: item_units, item_type: item_type, fixed_threshold: fixed_threshold,
      threshold_value: threshold_value, threshold: threshold, stockable: stockable
    }
  end

  def fetch_dispensing_units
    dispensing_unit_ids = @inventory_categories.pluck(:dispensing_unit_ids).flatten 
    @dispensing_units = Inventory::DispensingUnit.where(:id.in => dispensing_unit_ids, is_disable: false)
  end

  def fetch_categories
    @inventory_categories = Inventory::Category.where(:organisation_id.in => [current_user.organisation_id], is_disable: false)
  end

  def fetch_sub_categories
    @inventory_sub_categories = Inventory::SubCategory.where(:category_id.in =>  @inventory_categories.pluck(:id), is_disable: false)
  end

  def fetch_tax_groups
    country_id = current_facility.country_id
    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)
  end

  def fetch_generic_class_categories
    @generic_class_categories = GenericClass.all.pluck(:category).uniq&.sort
  end

  def fetch_items_index
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s

    if @inventory_store.present?
      if @category.present?
        if (@category.include? 'all_item') || @category_id.blank? #for store item index
          options = { store_id: @inventory_store.id, :category_id.in => @inventory_store.category_ids, level: 'store' }
        else
          options = { store_id: @inventory_store.id, :category_id.in => [@category_id], level: 'store'}
        end
      elsif @category_id.present?
        options = { store_id: @inventory_store.id, category_id: @category_id, level: 'store'}
      else
        options = { store_id: @inventory_store.id, :category_id.in => @inventory_store.category_ids, level: 'store' }
      end
      options = options.merge({ search: /#{Regexp.escape(query)}/i }) if query.present?
      # options = options.merge({ search: /#{Regexp.escape(query)}/i })
      if @stock == 'out_stock'
        options = options.merge(empty: true)
      elsif @stock == 'running_low'
        options = options.merge(running_low: true)
      end
      if @description.present?
        @items = Inventory::Item.where(options).is_active.order(params[:items].join("','")).skip(current_data_row).limit(30)
      elsif @stock.present?
        @items = Inventory::Item.where(options).is_active.order_by(stock: 'desc').skip(current_data_row).limit(30)
      else
        @items = Inventory::Item.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row).limit(30)
      end
    else #for org items index
      options = { organisation_id: current_user.organisation_id, level: 'organisation' }
      options = options.merge({ search: /#{Regexp.escape(query)}/i }) if query.present?
      @items = Inventory::Item.where(options).is_active.order_by(created_at: 'desc')
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_inventory_item
    @inventory_item = Inventory::Item.find(params[:id])
    @inventory_item_lots = Inventory::Item::Lot.where(
      item_id: params[:id], 'stock' => { '$gt' => 0.0 }, is_deleted: false
    )
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # def inventory_item_params
    # params.require(:inventory_item).permit(:name, :measure_unit, :divisible, :amount, :packaging, :stock => [:unit_price, :supply, :capacity, :threshold], :description => [:details, :manufacturer, :expiry])
    # NEEDS ATTENTION HERE!!!
    # params.permit(:name, :measure_unit, :divisible, :amount, :packaging, :stock => [:unit_price, :supply, :capacity, :threshold], :description => [:details, :manufacturer, :expiry])

    # THE UPDATE_TYPE DEFINE WHAT LEVEL OF UPDATE ARE WE DOING
  #   params.permit(:update_type, :category, :description, :checkoutable, :barcode, :batch_no, :manufacturer, :vendor, :dosage, :dispensing_unit, :sub_units, :stock, :inventory_capacity, :threshold, :price, :mark_up, :mrp, :list_price, :expiry, :warranty_expiry, :maintained_on, :maintainance_due, :condition)
  # end

  def generic_full_names(inventory_item)
    generic_names = inventory_item.generic_names
    generic_names.each do |gen_name|
      full_name = "#{gen_name.name} #{gen_name.quantity} #{gen_name.unit}"
      gen_name.update(full_name: full_name)
    end
    display_name = inventory_item.generic_names.pluck(:full_name)&.join(', ')
    generic_ids = inventory_item.generic_names.pluck(:generic_id)
    inventory_item.update(generic_display_name: display_name, generic_display_ids: generic_ids)
  end

  def inventory_item_params
    params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage, :unit_level,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :model_no, :brand,
        :barcode_present, :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id,
        :tax_rate, :tax_name, :tax_group_id, :system_generated_barcode, :department_name, :department_id, :stockable,
        :pricing_index, :measurement_unit, :category_id, :category_name, :sub_category_id, :non_stockable, :level,
        :dispensing_unit_id, :dispensing_unit_name, :sub_category_name, :vendor_id,
        custom_fields_attributes: [:name, { value: [] }, :_destroy],
        generic_names_attributes: [:name, :quantity, :unit, :generic_id],
        medicine_class_name_attributes: [:medicine_class, :medicine_class_id]
    )
  end

  def inventory_item_category_params(category)
    case category
    when 'medication'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :barcode_present,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index, :measurement_unit,
        custom_fields_attributes: [:name, { value: [] }, :_destroy], generic_names_attributes: [:name, :quantity, :unit, :generic_id],
        medicine_class_name_attributes: [:medicine_class, :medicine_class_id]
      )
    when 'implant'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :barcode_present,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index, :measurement_unit,
        custom_fields_attributes: [:name, { value: [] }, :_destroy], generic_names_attributes: [:name, :quantity, :unit, :generic_id],
        medicine_class_name_attributes: [:medicine_class, :medicine_class_id]
      )
    when 'consumable'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :barcode_present,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index, :measurement_unit,
        custom_fields_attributes: [:name, { value: [] }, :_destroy], generic_names_attributes: [:name, :quantity, :unit, :generic_id],
        medicine_class_name_attributes: [:medicine_class, :medicine_class_id]
      )
    when 'stockable'
      params.require(:inventory_item).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :store_id,
                                             :barcode_present, :system_generated_barcode, :department_name, :department_id)
    when 'asset'
      params.require(:inventory_item).permit(:category, :description, :checkoutable, :barcode, :manufacturer, :vendor,
                                             :price, :expiry, :warranty_expiry, :maintained_on, :maintainance_due, :condition, :store_id,
                                             :barcode_present, :system_generated_barcode, :department_name, :department_id)
    when 'miscellaneous'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :barcode_present,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index, :measurement_unit,
        custom_fields_attributes: [:name, { value: [] }, :_destroy], generic_names_attributes: [:name, :quantity, :unit, :generic_id],
        medicine_class_name_attributes: [:medicine_class, :medicine_class_id]
      )
    when 'optical_frame'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage, :barcode_present,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :model_no, :brand,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index,
        custom_fields_attributes: [:name, { value: [] }, :_destroy]
      )
    when 'optical_contact'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage, :barcode_present,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type, :power,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :model_no, :brand,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index,
        custom_fields_attributes: [:name, { value: [] }, :_destroy]
      )
    when 'optical_spectacle'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage, :barcode_present,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type, :power,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :model_no, :brand,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index,
        custom_fields_attributes: [:name, { value: [] }, :_destroy]
      )
    when 'optical'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage, :barcode_present,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :model_no, :brand,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index, :vendor_id,
        custom_fields_attributes: [:name, { value: [] }, :_destroy]
      )
    when 'optical_other'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage, :barcode_present,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :model_no, :brand,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index,
        custom_fields_attributes: [:name, { value: [] }, :_destroy]
      )
      when 'intraocular_lens'
      params.require(:inventory_item).permit(
        :description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage,
        :threshold, :threshold_value, :fixed_threshold, :sub_units, :package_type, :item_units, :item_type,
        :sub_package_units, :sub_package_type, :hsn_no, :expiry_present, :color_present, :barcode_present,
        :prescription_mandatory, :tax_inclusive, :facility_id, :organisation_id, :store_id, :tax_rate, :tax_name,
        :tax_group_id, :system_generated_barcode, :department_name, :department_id, :pricing_index, :measurement_unit,
        custom_fields_attributes: [:name, { value: [] }, :_destroy], generic_names_attributes: [:name, :quantity, :unit, :generic_id],
        medicine_class_name_attributes: [:medicine_class, :medicine_class_id]
      )

      # when 'optical_frame'
      #   params.require(:inventory_item).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :brand, :color, :gender, :pricing_index, :item_type, :model_no, :reference_no, :frame_type, :frame_material, :store_id) #:color_code, :label_color, :temple, :a, :b
      # when 'optical_contact'
      #   params.require(:inventory_item).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :brand, :color, :gender, :pricing_index, :item_type, :contact_type, :material, :replacement, :wearing_period, :power, :model_no, :reference_no, :store_id)
      # when 'optical'
      #   params.require(:inventory_item).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :brand, :color, :gender, :pricing_index, :item_type, :contact_type, :material, :replacement, :wearing_period, :power, :frame_type, :frame_material, :store_id) #:color_code, :label_color, :temple, :a, :b
      # when 'optical_other'
      #   params.require(:inventory_item).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :item_type, :threshold, :store_id)
      #

    end
  end

  def inventory_item_category_lot_params(category)
    case category
    when 'medication'
      params.permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry, :stock)
    when 'implant'
      params.permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry, :warranty_expiry, :stock)
    when 'consumable'
      params.permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry, :stock)
    when 'miscellaneous'
      params.permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry, :stock)
    when 'stockable'
      params.permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry, :warranty_expiry, :condition, :stock)
    when 'optical'
      params.permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry, :stock)
      # when 'contact'
      #   params.permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry, :stock)
    end
  end

  def inventory_item_category_update_params(category)
    case category
    when 'medication'
      params.require(:inventory_item_medication).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :dispensing_unit, :dosage, :inventory_capacity, :threshold, :sub_units, :packaging_type)
    when 'implant'
      params.require(:inventory_item_implant).permit(:description, :category, :checkoutable, :barcode, :manufacturer)
    when 'consumable'
      params.require(:inventory_item_consumable).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :sub_units, :packaging_type)
    when 'stockable'
      params.require(:inventory_item_stockable).permit(:description, :category, :checkoutable, :barcode, :manufacturer)
    when 'asset'
      params.require(:inventory_item_asset).permit(:category, :description, :checkoutable, :barcode, :manufacturer, :vendor, :price, :expiry, :warranty_expiry, :maintained_on, :maintainance_due, :condition)
    when 'miscellaneous'
      params.require(:inventory_item_miscellaneous).permit(:category, :description, :checkoutable, :barcode, :manufacturer)
    when 'frame'
      params.require(:inventory_item_optical_frame).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :brand, :color, :gender, :pricing_index, :item_type, :model_no, :reference_no, :frame_type, :frame_material) #:color_code, :label_color, :temple, :a, :b
    when 'contact'
      params.require(:inventory_item_optical_contact).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :brand, :color, :gender, :pricing_index, :item_type, :contact_type, :material, :replacement, :wearing_period, :power, :model_no, :reference_no)
    when 'optical'
      params.require(:inventory_item_optical).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :brand, :color, :gender, :pricing_index, :item_type, :contact_type, :material, :replacement, :wearing_period, :power, :frame_type, :frame_material) #:color_code, :label_color, :temple, :a, :b
    when 'other'
      params.require(:inventory_item_optical_other).permit(:description, :category, :checkoutable, :barcode, :manufacturer, :item_type, :threshold)
    end
  end

  # def inventory_item_category_stock_params(category)
  #   case category
  #   when 'medication'
  #     params.permit(:expiry, :list_price, :mark_up, :mrp, :price, :vendor, :manufacturer)
  #   when 'implant'
  #     params.permit(:expiry, :list_price, :mark_up, :mrp, :price, :vendor, :manufacturer)
  #   when 'consumable'
  #     params.permit(:expiry, :list_price, :mark_up, :mrp, :price, :vendor, :manufacturer)
  #   when 'miscellaneous'
  #     params.permit(:expiry, :list_price, :mark_up, :mrp, :price, :vendor, :manufacturer)
  #   when 'stockable'
  #     params.permit(:expiry, :warranty_expiry, :price, :vendor, :manufacturer)
  #   end
  # end

  def stock_update_params
    params.permit(:vendor, :expiry, :price, :mrp, :mark_up, :stock, :list_price, :warranty_expiry)
  end

  def get_lots_for_quantity(item, quantity)
    lots_array = []
    lots = item.lots.where(is_deleted: false).order('expiry asc')
    # puts "Total lots found #{lots.length}"
    while quantity > 0
      lots.each do |lot|
        # # puts "quantity before - #{quantity}"
        if lot.stock >= quantity
          lots_array << lot.id
          quantity = 0
        else
          lots_array << lot.id
          quantity -= lot.stock
        end
      end
      # # puts "quantity after - #{quantity}"
    end
    lots_array
  end

  def params_log_checkout_item(item, lot)
    # obj = item.as_json.merge(lot.as_json)
    objs = ActionController::Parameters.new(item.as_json.merge(lot.as_json))
    objs.permit(:item_code, :category, :description, :barcode, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :manufacturer, :expiry)
  end

  def create_log_checkout_params(obj)
    objs = ActionController::Parameters.new(obj.as_json)
    objs.permit(:item_code, :category, :description, :barcode, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :manufacturer, :expiry)
  end

  def get_categories(category)
    ['asset', 'consumable', 'custom_field', 'generic_name', 'implant', 'intraocular_lens', 'intraocular', 'lot', 'medication', 'medicine_class_name', 'miscellaneous', 'stockable', 'variant', 'optical_frame', 'optical_contact', 'optical_spectacle'].select{|cat| cat == category}.first
  end
  # EOF get_categories
end
