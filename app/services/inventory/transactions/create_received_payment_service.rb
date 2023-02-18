class Inventory::Transactions::CreateReceivedPaymentService
  class << self
    def call(invoice_id, _user, payment_received_breakup, type)
      amount = payment_received_breakup['amount'].to_f
      amount_received = payment_received_breakup['amount_received'].to_f
      if type == 'order'
        inventory_invoice = Invoice::InventoryOrder.find_by(id: invoice_id)
      else
        inventory_invoice = Invoice::InventoryInvoice.find_by(id: invoice_id)
        inventory_order = Invoice::InventoryOrder.find_by(id: inventory_invoice.order_id)
      end
      payment_breakups = inventory_invoice.payment_received_breakups
      payment_breakup = payment_breakups.new
      payment_breakup.amount = amount
      payment_breakup.date = Date.current
      payment_breakup.time = Time.current
      payment_breakup.received_by = payment_received_breakup['received_by']
      payment_breakup.received_from = payment_received_breakup['received_from']
      payment_breakup.mode_of_payment = payment_received_breakup['mode_of_payment']
      payment_breakup.currency_id = payment_received_breakup['currency_id']
      payment_breakup.currency_symbol = payment_received_breakup['currency_symbol']
      payment_breakup.amount_received = amount_received
      payment_breakup.save
      if type == 'order'
        Invoice::CreateOrderNumberService.call(inventory_invoice)
      else
        Invoice::CreateBillNumberService.call(inventory_invoice)
      end
      inventory_invoice.update(payment_received: (inventory_invoice.payment_received.to_f + amount).to_f.round(2),
                               payment_pending: inventory_invoice.payment_pending.to_f.round(2) - amount,
                               amount_remaining: inventory_invoice.amount_remaining.to_f.round(2) - amount)

      return unless inventory_invoice.amount_remaining.to_f == 0

      inventory_invoice.update(payment_completed: true, payment_completed_date: Date.current)

      return unless inventory_order.present?

      inventory_order.update(
        payment_received: inventory_invoice.payment_received, payment_pending: inventory_invoice.payment_pending,
        amount_remaining: inventory_invoice.amount_remaining, advance_payment: inventory_invoice.advance_payment,
        payment_completed: inventory_invoice.payment_completed,
        payment_completed_date: inventory_invoice.payment_completed_date
      )
    end
  end
end
