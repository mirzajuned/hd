class Invoice::CreateInventoryInvoiceService
  def self.call(order_id, user_id, region_master_id)
    inventory_order = Invoice::InventoryOrder.find_by(id: order_id)
    inventory_invoice = Invoice::InventoryInvoice.new(inventory_order.attributes.except(:_id, :state_transitions, :order_number))
    bkp_bill_number = Invoice::InventoryInvoicesHelper.increment_and_create_bill_number(
      inventory_order.store_id.to_s, inventory_order.facility_id.to_s
    )
    inventory_invoice.bkp_bill_number = bkp_bill_number
    inventory_invoice.order_id = inventory_order.id
    inventory_invoice.save!
    bill_number = SequenceManagers::GenerateSequenceService.call(
      'invoice', inventory_invoice.id.to_s,
      { organisation_id: inventory_invoice.organisation_id.to_s, facility_id: inventory_invoice.facility_id.to_s, region_id: region_master_id, department_id: inventory_invoice.department_id }
    )
    inventory_invoice.update(bill_number: bill_number)
    Invoice::CreateBillNumberService.call(inventory_invoice)
    inventory_order.update(
      is_invoice_created: true, invoice_created_on: Time.current, 
      invoice_created_by: user_id, invoice_id: inventory_invoice.id
    )
    inventory_invoice.id
  end
end
