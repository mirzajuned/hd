class Inventory::Orders::CreatePurchaseOrderService
  class << self
    def call(indent_id, user_id)
      @indent_order = Inventory::Order::Indent.find_by(id: indent_id)
      @vendor = Inventory::Vendor.find_by(id: @indent_order.vendor_id)
      @vendor_location = Inventory::VendorLocation.find_by(vendor_id: @vendor.id)
      @user = User.find_by(id: user_id)
      @facility = Facility.find_by(id: @indent_order.facility_id)
      @store = Inventory::Store.find_by(id: @indent_order.store_id)
      @optical_order = Invoice::InventoryOrder.find_by(id: @indent_order.optical_order_id)
      return unless @indent_order.items.present?

      purchase_order = Inventory::Order::Purchase.new
      purchase_order.note = 'Created from optical order'
      purchase_order.po_type = 'Urgent'
      purchase_order.order_date = Date.current
      purchase_order.order_date_time = Time.current
      purchase_order.vendor_credit_days = @vendor.credit_days
      if @vendor.po_expiry_days.present?
        purchase_order.po_expiry_date = Date.current + @vendor.po_expiry_days.to_i
      end
      purchase_order.vendor_location_id = @vendor_location.id
      purchase_order.vendor_id = @vendor.id
      purchase_order.vendor_name = @vendor.name
      purchase_order.ship_to_store = @store.id
      purchase_order.bill_to_store = @store.id
      purchase_order.entry_type = 'purchase'
      purchase_order.entered_by = @user.fullname
      purchase_order.user_id = @user.id
      purchase_order.store_id = @indent_order.store_id
      purchase_order.facility_id = @indent_order.facility_id
      purchase_order.organisation_id = @indent_order.organisation_id
      purchase_order.department_id = @indent_order.department_id
      purchase_order.department_name = @indent_order.department_name
      purchase_order.created_from_optical_order = true
      purchase_order.email_delivered = false
      purchase_display_id = Invoice::InventoryInvoicesHelper.increment_and_create_order_number(
        @indent_order.organisation_id.to_s
      )
      purchase_order.purchase_display_id = purchase_display_id
      purchase_order.indent_id = @indent_order.id

      purchase_total_cost = 0
      total_purchase_tax_amount = 0
      total_net_amount = 0
      @indent_order.items.each do |item|
        vendor_rate = Inventory::VendorRate.find_by(variant_reference_id: item.variant_reference_id)
        unit_cost_without_tax = vendor_rate&.rate || 0
        paid_stock = item.stock
        tax_rate = item.tax_rate
        total_cost = unit_cost_without_tax * paid_stock
        amt_before_tax = total_cost
        purchase_total_cost += total_cost
        tax_amount = (((tax_rate * amt_before_tax) / 100))
        purchase_tax_amount = tax_amount
        cost_after_tax = total_cost + tax_amount
        purchase_order_item_params = item.attributes.except(:_id)
        item_taxable_amount_with_disc = amt_before_tax
        total_purchase_tax_amount += purchase_tax_amount
        total_net_amount += cost_after_tax
        purchase_order_item_params.merge!(
          paid_stock: item.stock, stock: item.stock, purchase_tax_amount: purchase_tax_amount, total_cost: total_cost,
          amount_after_tax: cost_after_tax, item_taxable_amount_with_disc: item_taxable_amount_with_disc,
          unit_cost_without_tax: unit_cost_without_tax
        )
        purchase_order.items.build(purchase_order_item_params)
      end
      purchase_order.total_cost = purchase_total_cost&.round(2)
      purchase_order.net_amount = total_net_amount&.round(2)
      purchase_order.tax_amount = total_purchase_tax_amount&.round(2)
      purchase_order.discount = 0.0
      purchase_order.total_other_charges_amount = 0.0
      purchase_order.optical_order_id = @indent_order.optical_order_id
      purchase_order.requisition_order_id = @indent_order.requisition_order_id

      @record_details = { record_name: 'PurchaseOrder', record_id: purchase_order.id.to_s,
                          record_model: 'PurchaseOrder' }
      @sender_details = { sender_name: @user.fullname, sender_id: @user.id.to_s, sender_role: @user.primary_role }
      @receiver_details = { vendor_email: @vendor&.email, vendor_name: @vendor&.name,
                            vendor_id: @vendor&.id.to_s }
      @facility_details = { facility_name: @facility.name, facility_id: @facility.id.to_s }
      @subject = "no reply | PO No: #{purchase_order.purchase_display_id}  | Optical Order No. : #{@optical_order.order_number}"
      @mail_text = "<p>#{@store.name}</p>"

      purchase_order.set_approved(@user, '') if purchase_order.save!

      @indent_order.update(status: 'Completed', indent_completed: true, is_closed: true, transaction_present: true,
                           purchase_order_id: purchase_order.id)
      @indent_order.items.each do |item|
        stock = item&.stock.to_f || 0
        item.update(stock_received_status: true, stock_received: stock)
        variant = Inventory::Item::Variant.find_by(id: item.default_variant_id)
        if variant.to_a.present?
          variant.pending_po_quantity = variant.pending_po_quantity + stock
          variant.save!
        end
      end

      @email_tracker = MailRecordTracker.new(
        organisation_id: purchase_order.organisation_id, record_details: @record_details,
        sender_details: @sender_details, receiver_details: @receiver_details, facility_details: @facility_details,
        mail_text: @mail_text, subject: @subject, purchase_order_id: purchase_order.id
      )
      @email_tracker.save!
    end
  end
end
