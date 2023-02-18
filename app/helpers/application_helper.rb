module ApplicationHelper
  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, 'remove_fields(this)')
  end

  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, child_index: "new_#{association}") do |builder|
      render(association.to_s.singularize + '_fields', f: builder)
    end
    link_to(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"))
  end

  def replace_blank(value, replace = '--')
    value = replace if value.blank?

    value # return
  end

  def inventory_stock_receiving(purchase_transaction_item)
    purchase_transaction_item.try(:stock).to_f - (purchase_transaction_item.try(:stock_received).to_f + purchase_transaction_item.try(:stock_blocked).to_f)
  end

  def inventory_stock_paid_receiving(purchase_transaction_item)
    purchase_transaction_item.try(:paid_stock).to_f - (purchase_transaction_item.try(:stock_paid_received).to_f + purchase_transaction_item.try(:stock_paid_blocked).to_f)
  end

  def inventory_max_stock(purchase_transaction_item,purchase_transaction_id,item_type)
    po_items = Inventory::Order::Purchase.find_by(id: purchase_transaction_id).items
    if item_type == "paid"
    po_items.find_by(id: purchase_transaction_item.po_item_id)&.stock_paid_blocked
    elsif item_type == "free"
    po_items.find_by(id: purchase_transaction_item.po_item_id)&.stock_free_blocked
    else
      po_items.find_by(id: purchase_transaction_item.po_item_id)&.stock_blocked
    end
  end

  def inventory_receiving_max_stock(purchase_transaction_item,purchase_transaction_id,item_type)
    po_items = Inventory::Order::Purchase.find_by(id: purchase_transaction_id).items
    po_item = po_items.find_by(id: purchase_transaction_item.po_item_id)
    if item_type == "paid"
    po_item&.paid_stock - (po_item&.stock_paid_received)
    # po_item&.paid_stock - (po_item&.stock_paid_received + po_item&.stock_paid_blocked)
    elsif item_type == "free"
      po_item&.stock_free_unit.to_f - (po_item&.stock_free_received.to_f)
    # po_item&.stock_free_unit - (po_item&.stock_free_received + po_item&.stock_free_blocked)
    else
      # po_item&.stock - (po_item&.stock_received)
      po_item&.stock - (po_item&.stock_received.to_f + po_item&.stock_blocked.to_f)
    end
  end

  def inventory_stock_free_receiving(purchase_transaction_item)
    purchase_transaction_item.try(:stock_free_unit).to_f - (purchase_transaction_item.try(:stock_free_received).to_f + purchase_transaction_item.try(:stock_free_blocked).to_f)
  end

  def sub_category_name(inventory_object)
    Inventory::SubCategory.find_by(id: inventory_object.sub_category_id).name if inventory_object.sub_category_id
  end

  def organization_expiry_calendar
    current_organisation['inventory_expiry_format'] == 'MM/YYYY' ? 'none' : 'table'
  end

  def rol_rule_store_names
    store_ids = Inventory::RolRule.pluck(:store_id)
    if store_ids
      stores = Inventory::Store.find(store_ids)
      stores.collect do |store|
        department = "-#{store.department_name}" if store.department_name.present?
        ["#{store.name}#{department}", store.id]
      end
    else
      []
    end
  end

  def rol_rule_category_names
    variant_ids = Inventory::RolRule.pluck(:variant_id)
    category_ids = Inventory::Item::Variant.find(variant_ids).pluck(:category_id)
    if category_ids.compact.present?
      categories = Inventory::Category.find(category_ids.compact)
      categories.collect { |category| [category.name, category.id] }
    else
      []
    end
  end

  def inventory_item_form_params
    form_params = { format: :js, remote: true, validate: true }
    if @inventory_item.new_record?
      form_params.merge!(url: inventory_items_path(@inventory_item), method: :post)
    else
      form_params.merge!(url: inventory_item_path(@inventory_item))
    end
  end

  def inventory_medicine_classes
    return unless @inventory_item.medicine_class_name.present?

    @inventory_item.medicine_class_name.collect(&:medicine_class).join(', ')
  end

  def vendor_rate_vendor_names
    vendor_ids = Inventory::VendorRate.pluck(:vendor_id)
    vendors = Inventory::Vendor.find(vendor_ids)
    vendors.collect { |vendor| [vendor.name, vendor.id] }
  end

  def facility_font_size
    if @_request
      facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
      if @print_setting
        @templatetype.present? ? facility_setting.try(:template_font_size) : facility_setting.try(:bills_font_size)
      end
    end
  end

  def heading_font_size
    "font-size: #{facility_font_size}px !important;" if facility_font_size
  end

  def text_font_size
    "font-size: #{facility_font_size.to_i - 0}px !important;" if facility_font_size
  end

  def template_header_font_size
    "font-size: #{facility_template_header_font_size.to_i - 0}px !important;" if facility_template_header_font_size
  end

  def facility_template_header_font_size
    if @_request
      facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
      if @print_setting
        facility_setting.try(:template_header_font_size)
      end
    end
  end

  def inventory_item_medicine_classes(item)
    if item.medicine_class_name.present?
      item.medicine_class_name.collect(&:medicine_class).join(", ")
    end
  end

  def get_facility_fonts
    @type == 'bills_font_size' ? [(7..12), '8px'] : (@type == "template_header_font_size" ? [(8..13), '9px'] : [(8..14), '11px'])
  end

  def user_authorized_by_policy?(policy_id)
    Authorization::PolicyHelper.verification(current_user.id, policy_id)
  end
end
