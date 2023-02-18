module Inventory::Audit::History::CreateService
  def self.call(stock_before, lot, transaction_type, transaction_id, current_user_id)
    stock_after = lot.stock || 0
    unit_cost = lot.unit_cost || 0
    stock_value = stock_after - stock_before

    user_name = User.find_by(id: current_user_id).try(:fullname)

    flow = if stock_value > 0
             'In'
           else
             'Out'
           end
    bill_number = case transaction_type
                  when 'Invoice'
                    Invoice::InventoryInvoice.find(transaction_id).bill_number
                  when 'Return'
                    Inventory::Transaction::Return.find(transaction_id).return_bill_number
                  when 'Purchase'
                    Inventory::Transaction::Purchase.find(transaction_id).purchase_display_id
                  when 'Adjustment'
                    Inventory::Transaction::Adjustment.find(transaction_id).adjustment_display_id
                  when 'Transfer'
                    Inventory::Transaction::Transfer.find(transaction_id).transfer_display_id
                  when 'Purchase Return'
                    Inventory::Transaction::VendorReturn.find(transaction_id).purchase_return_id
                  when 'Receive'
                    Inventory::Transaction::Receive.find(transaction_id)&.receive_display_id
                  when 'Stock Receive Note'
                    Inventory::Transaction::StockReceiveNote.find(transaction_id)&.srn_display_id
                  when 'Stock Opening'
                    Inventory::Transaction::StockOpening.find(transaction_id)&.stock_opening_display_id
                  when 'Direct Stock'
                    Inventory::Transaction::DirectStock.find(transaction_id)&.direct_stock_display_id
                  when 'Re-stock'
                    Inventory::Transaction::Transfer.find(transaction_id).transfer_display_id
                  end
    @transaction_history = Inventory::Audit::History.new
    @transaction_history.stock_before = stock_before&.round(2)
    @transaction_history.stock_after = stock_after&.round(2)
    @transaction_history.stock_value = stock_value&.round(2)

    @transaction_history.amount_before = (stock_before * unit_cost)&.round(2)
    @transaction_history.amount_after = (stock_after * unit_cost)&.round(2)
    @transaction_history.amount_value = (stock_value * unit_cost)&.round(2)

    @transaction_history.transaction_date = Date.today
    @transaction_history.transaction_time = Time.current
    @transaction_history.flow = flow

    @transaction_history.transaction_type = transaction_type
    @transaction_history.transaction_id = transaction_id

    @transaction_history.lot_id = lot.id
    @transaction_history.item_id = lot.item_id
    @transaction_history.variant_id = lot.variant_id
    @transaction_history.batch_no = lot.batch_no
    @transaction_history.variant_code = lot.variant_code
    @transaction_history.store_id = lot.store_id
    @transaction_history.user_name = user_name
    @transaction_history.user_id = current_user_id
    @transaction_history.facility_id = lot.facility_id
    @transaction_history.organisation_id = lot.organisation_id
    @transaction_history.list_price = lot.list_price
    @transaction_history.unit_cost = unit_cost
    @transaction_history.lot_description = lot.description
    @transaction_history.variant_identifier = lot.variant_identifier
    @transaction_history.custom_field_data = lot.custom_field_data
    @transaction_history.model_no = lot.model_no
    @transaction_history.item_name = lot.description
    @transaction_history.lot_identifier = lot.custom_field_tags&.reject(&:blank?)&.join(', ')
    @transaction_history.bill_number = bill_number
    @transaction_history.sub_store_id = lot.sub_store_id
    @transaction_history.sub_store_name = lot.sub_store_name
    @transaction_history.net_unit_cost_without_tax = lot.net_unit_cost_without_tax
    if transaction_type == "Purchase Return"
      tax_amount = (((stock_value&.abs.to_f * lot.pr_net_unit_cost_without_tax.to_f) * (lot.tax_rate.to_i))/100) || 0
      total_transaction_cost = (stock_value&.abs.to_f * lot.pr_net_unit_cost_without_tax.to_f) + tax_amount
      amount_value = (stock_value&.abs.to_f * lot.pr_net_unit_cost_without_tax) + tax_amount
      # @transaction_history.amount_value = amount_value&.round(2)
    else
      tax_amount = (((stock_value&.abs.to_f * lot.net_unit_cost_without_tax.to_f) * (lot.tax_rate.to_i))/100) || 0
      total_transaction_cost = (stock_value&.abs.to_f * lot.net_unit_cost_without_tax.to_f) + tax_amount
      amount_value = (stock_value&.abs.to_f * lot.net_unit_cost_without_tax.to_f) + tax_amount
      # @transaction_history.amount_value = amount_value&.round(2)
    end    
    @transaction_history.tax_amount = tax_amount    
    @transaction_history.total_transaction_cost = total_transaction_cost

    Inventory::Audit::Balance::CreateService.call(@transaction_history, current_user_id) if @transaction_history.save!
  end
end
