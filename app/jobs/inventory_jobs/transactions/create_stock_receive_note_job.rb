class InventoryJobs::Transactions::CreateStockReceiveNoteJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    inventory_order = Invoice::InventoryOrder.find_by(id: args[0])
    user = User.find_by(id: args[1])
    store = Inventory::Store.find_by(id: inventory_order.store_id)
    sub_store = store.sub_stores[0]
    stock_receive_note = Inventory::Transaction::StockReceiveNote.new
    stock_receive_note.note = 'created from job'
    stock_receive_note.vendor_id = ''
    stock_receive_note.vendor_name = ''
    stock_receive_note.transaction_date = Date.current.strftime('%d/%m/%Y')
    stock_receive_note.transaction_time = Time.current
    stock_receive_note.entry_type = 'stock_receive_note'
    stock_receive_note.entered_by = user.fullname
    stock_receive_note.user_id = user.id
    stock_receive_note.store_id = store.id
    stock_receive_note.facility_id = inventory_order.facility_id
    stock_receive_note.organisation_id = inventory_order.organisation_id
    stock_receive_note.department_id = store.department_id
    stock_receive_note.department_name = store.department_name
    stock_receive_note.bill_type = ''
    stock_receive_note.challan_number = ''
    stock_receive_note.challan_date = ''
    stock_receive_note.bill_number = ''
    stock_receive_note.bill_date = ''
    srn_display_id = InventoryHelper.increment_and_create_srn_number(store.organisation_id.to_s)
    stock_receive_note.srn_display_id = srn_display_id
    stock_receive_note.order_id = inventory_order.id
    total_cost = 0
    taxable_amount = 0
    @tax_breakup = []

    inventory_order.items.each_with_index do |item, _index|
      next unless item.srn_required

      @item = Inventory::Item.find_by(id: item.item_id)
      variant = Inventory::Item::Variant.find_by(item_id: @item.id)

      srn_item = stock_receive_note.items.new
      srn_item.item_id = @item.id
      srn_item.category = @item.category
      srn_item.category_id = @item.category_id
      srn_item.item_reference_id = @item.reference_id
      srn_item.facility_id = item.facility_id
      srn_item.store_id = item.store_id
      srn_item.organisation_id = item.organisation_id
      srn_item.order_id = inventory_order.id
      srn_item.variant_code = variant.variant_code
      srn_item.item_code = @item.item_code
      srn_item.variant_id = variant.id
      srn_item.variant_reference_id = variant.reference_id
      srn_item.sub_store_id = sub_store.id
      srn_item.sub_store_name = sub_store.name
      srn_item.description = item.description
      srn_item.list_price = item.list_price
      srn_item.unit_cost = item.list_price
      srn_item.unit_non_taxable_amount = item.unit_non_taxable_amount
      srn_item.unit_taxable_amount = item.unit_taxable_amount
      srn_item.stock = item.quantity
      srn_item.tax_name = item.tax_name
      srn_item.tax_rate = item.tax_rate
      srn_item.tax_group_id = item.tax_group_id
      srn_item.tax_inclusive = item.tax_inclusive
      unit_cost_price = item.list_price || 0
      tax_amount = (unit_cost_price * item.tax_rate) / (100 + item.tax_rate)
      unit_cost_without_tax = unit_cost_price - tax_amount
      srn_item.unit_cost_without_tax = unit_cost_without_tax
      srn_item.unit_purchase_tax_amount = tax_amount
      srn_item.unit_non_taxable_amount = item.unit_non_taxable_amount
      item_cost_without_tax = unit_cost_without_tax * item.quantity&.to_f
      srn_item.item_cost_without_tax = item_cost_without_tax
      srn_item.taxable_amount_with_disc = item_cost_without_tax
      srn_item.unit_taxable_amount = item.unit_taxable_amount
      srn_item.purchase_tax_amount = tax_amount * item.quantity&.to_f
      srn_item.total_cost = item.total_list_price
      total_cost += item.total_list_price
      taxable_amount += item_cost_without_tax
      item.tax_group.each do |group|
        data = {}
        data['_id'] = group['_id']
        data['name'] = group['name']
        data['amount'] = group['amount']
        data['taxable_amount'] = item.unit_non_taxable_amount&.round(2)
        name = data['name']&.scan(/\d+|[A-Za-z]+/)
        data['tax_rate'] = name[1] if name.present?
        data['tax_type'] = name[0] if name.present?
        @tax_breakup << data
      end
    end

    stock_receive_note.total_cost = total_cost
    stock_receive_note.net_amount = total_cost
    stock_receive_note.taxable_amount = taxable_amount&.round(2)
    stock_receive_note.tax_breakup = @tax_breakup
    return unless stock_receive_note.save!

    Inventory::Transactions::UpdateStockReceiveNoteService.call(stock_receive_note.id, user.id)
  end
end
