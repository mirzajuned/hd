class Inventory::Transactions::CreateAdvancePaymentService
  class << self
    def call(invoice_id, advance_payment_id, user_name, advance_amount, advance_type, type)
      if type == 'order'
        inventory_invoice = Invoice::InventoryOrder.find_by(id: invoice_id)
        payment_breakup = inventory_invoice.advance_payment_breakups.new
        bill_order_number = inventory_invoice.order_number
      else
        inventory_invoice = Invoice::InventoryInvoice.find_by(id: invoice_id)
        inventory_order = Invoice::InventoryOrder.find_by(id: inventory_invoice.order_id)
        payment_breakup = inventory_invoice.advance_payment_breakups.new
        bill_order_number = inventory_invoice.bill_number
      end
      advance_payment = AdvancePayment.find_by(id: advance_payment_id)
      payment_breakup.advance_payment_id = advance_payment.id
      payment_breakup.advance_display_id = advance_payment.advance_display_id.to_s
      payment_breakup.currency_symbol = advance_payment.currency_symbol
      payment_breakup.currency_id = advance_payment.currency_id
      payment_breakup.reason = advance_payment.reason
      payment_breakup.mode_of_payment = advance_payment.mode_of_payment
      payment_breakup.advance_date = advance_payment.payment_date
      payment_breakup.advance_time = advance_payment.payment_time
      payment_breakup.date = Date.current
      payment_breakup.time = Time.current
      amount = advance_amount.to_f
      payment_breakup.advance_amount = amount
      payment_breakup.amount = amount
      mode_of_payment = advance_payment.mode_of_payment
      if mode_of_payment == 'Cash'
        payment_breakup.cash = amount
      elsif mode_of_payment == 'Card'
        payment_breakup.card = amount
        payment_breakup.card_number = advance_payment.card_number
        payment_breakup.card_transaction_note = advance_payment.card_transaction_note
      elsif mode_of_payment == 'Paytm'
        payment_breakup.paytm_transaction_id = advance_payment.paytm_transaction_id
        payment_breakup.paytm_transaction_note = advance_payment.paytm_transaction_note
      elsif mode_of_payment == 'Google Pay'
        payment_breakup.gpay_transaction_id = advance_payment.gpay_transaction_id
        payment_breakup.gpay_transaction_note = advance_payment.gpay_transaction_note
      elsif mode_of_payment == 'PhonePe'
        payment_breakup.phonepe_transaction_id = advance_payment.phonepe_transaction_id
        payment_breakup.phonepe_transaction_note = advance_payment.phonepe_transaction_note
      elsif mode_of_payment == 'Online Transfer'
        payment_breakup.transfer_date = advance_payment.transfer_date
        payment_breakup.transfer_note = advance_payment.transfer_note
      elsif mode_of_payment == 'Cheque'
        payment_breakup.cheque_date = advance_payment.cheque_date
        payment_breakup.cheque_note = advance_payment.cheque_note
      elsif mode_of_payment == 'Others'
        payment_breakup.other_transaction_id = advance_payment.other_transaction_id
        payment_breakup.other_note = advance_payment.other_note
      end
      payment_breakup.save
      advance_payment.amount_remaining = if advance_type == 'advance_against_order'
                                           0
                                         else
                                           advance_payment.amount_remaining - amount
                                         end
      advance_payment.advance_state = ('Settled' if advance_payment.amount_remaining.to_i == 0) || 'None'
      advance_payment.advance_history = advance_payment.try(:advance_history) || []
      advance_history = {
        advance_payment_breakup_id: payment_breakup.id.to_s, invoice_id: inventory_invoice.id.to_s,
        invoice_type: 'Optical', type: 'Adjusted', user_name: user_name, amount: amount,
        event_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), bill_number: bill_order_number
      }
      advance_payment.advance_history << advance_history
      advance_payment.save
      InvoiceJobs::AdvancePaymentJob.perform_later(advance_payment.id.to_s) if advance_type == 'advance_against_patient'

      inventory_invoice.update(payment_received: inventory_invoice.payment_received.to_f + amount,
                               payment_pending: inventory_invoice.payment_pending.to_f - amount,
                               amount_remaining: inventory_invoice.amount_remaining.to_f - amount,
                               advance_payment: inventory_invoice.advance_payment.to_f + amount)
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
