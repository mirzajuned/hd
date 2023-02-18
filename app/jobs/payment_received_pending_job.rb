class PaymentReceivedPendingJob < ActiveJob::Base
  queue_as :urgent
  def perform(invoice_id)
    invoice = Invoice.find_by(id: invoice_id)
    if invoice.try(:_type).present?
      invoice_type = invoice._type.split("::")[-1]
      invoice_payment_receiveds = Invoice::PaymentReceived.where(invoice_id: invoice.id)
      invoice_payment_pendings = Invoice::PaymentPending.where(invoice_id: invoice.id)
      inactive_invoice_payment_received_ids = invoice_payment_receiveds.where(is_active: false).pluck(:id).map(&:to_s)
      inactive_invoice_payment_pending_ids = invoice_payment_pendings.where(is_active: false).pluck(:id).map(&:to_s)
      invoice_payment_receiveds.update_all(is_active: false)
      invoice_payment_pendings.update_all(is_active: false)

      invoice_payment_received_ids = []
      invoice_payment_pending_ids = []

      invoice.payment_received_breakups.each do |payment_received|
        invoice_payment_received = Invoice::PaymentReceived.find_by(payment_received_id: payment_received.id.to_s) || Invoice::PaymentReceived.new

        Analytics::Financial::PayerPaymentResetService.call(invoice_payment_received.id.to_s, "Invoice::PaymentReceived")
        Analytics::Financial::PaymentModeResetService.call(invoice_payment_received.id.to_s, "Invoice::PaymentReceived")

        if invoice.patient_id == payment_received.received_from
          received_from_type = "Patient"
        else
          payer_master = PayerMaster.find_by(id: payment_received.received_from)
          if payer_master.present?
            received_from_type = "Contact"
          end
        end

        invoice_payment_received[:amount] = payment_received.amount
        invoice_payment_received[:date] = payment_received.date
        invoice_payment_received[:time] = payment_received.time
        invoice_payment_received[:received_by] = payment_received.received_by
        invoice_payment_received[:received_from] = payment_received.received_from
        invoice_payment_received[:received_from_type] = received_from_type
        invoice_payment_received[:currency_symbol] = payment_received.currency_symbol
        invoice_payment_received[:currency_id] = payment_received.currency_id
        invoice_payment_received[:mode_of_payment] = payment_received.mode_of_payment
        invoice_payment_received[:cash] = payment_received.cash
        invoice_payment_received[:card] = payment_received.card
        invoice_payment_received[:card_number] = payment_received.card_number
        invoice_payment_received[:card_transaction_note] = payment_received.card_transaction_note
        invoice_payment_received[:paytm_transaction_id] = payment_received.paytm_transaction_id
        invoice_payment_received[:paytm_transaction_note] = payment_received.paytm_transaction_note
        invoice_payment_received[:gpay_transaction_id] = payment_received.gpay_transaction_id
        invoice_payment_received[:gpay_transaction_note] = payment_received.gpay_transaction_note
        invoice_payment_received[:phonepe_transaction_id] = payment_received.phonepe_transaction_id
        invoice_payment_received[:phonepe_transaction_note] = payment_received.phonepe_transaction_note
        invoice_payment_received[:cheque_date] = payment_received.cheque_date
        invoice_payment_received[:cheque_note] = payment_received.cheque_note
        invoice_payment_received[:transfer_date] = payment_received.transfer_date
        invoice_payment_received[:transfer_note] = payment_received.transfer_note
        invoice_payment_received[:other_transaction_id] = payment_received.other_transaction_id
        invoice_payment_received[:other_note] = payment_received.other_note
        invoice_payment_received[:payment_received_breakup_id] = payment_received._id
        invoice_payment_received[:invoice_type] = invoice_type
        invoice_payment_received[:payment_received_id] = payment_received.id.to_s
        invoice_payment_received[:invoice_id] = invoice.id
        invoice_payment_received[:facility_id] = invoice.facility_id
        invoice_payment_received[:organisation_id] = invoice.organisation_id
        invoice_payment_received[:is_active] = true

        if invoice_payment_received.save
          invoice_payment_received_ids << invoice_payment_received.id.to_s
        end
      end
      # update payment received
      invoice_amount_received = invoice.payment_received_breakups.pluck(:amount_received).map{|i| i.to_f}.inject(0, :+)
      invoice.set(amount_received: invoice_amount_received)
      invoice.payment_pending_breakups.each do |payment_pending|
        invoice_payment_pending = Invoice::PaymentPending.find_by(payment_pending_id: payment_pending.id.to_s) || Invoice::PaymentPending.new

        Analytics::Financial::PayerPaymentResetService.call(invoice_payment_pending.id.to_s, "Invoice::PaymentPending")

        if invoice.patient_id == payment_pending.received_from
          received_from_type = "Patient"
        else
          payer_master = PayerMaster.find_by(id: payment_pending.received_from)
          if payer_master.present?
            received_from_type = "Contact"
          end
        end

        invoice_payment_pending[:amount] = payment_pending.amount
        invoice_payment_pending[:date] = invoice.created_at
        invoice_payment_pending[:received_from] = payment_pending.received_from
        invoice_payment_pending[:received_from_type] = received_from_type
        invoice_payment_pending[:currency_symbol] = payment_pending.currency_symbol
        invoice_payment_pending[:currency_id] = payment_pending.currency_id
        invoice_payment_pending[:payment_pending_breakup_id] = payment_pending._id
        invoice_payment_pending[:invoice_type] = invoice_type
        invoice_payment_pending[:payment_pending_id] = payment_pending.id.to_s
        invoice_payment_pending[:invoice_id] = invoice.id
        invoice_payment_pending[:facility_id] = invoice.facility_id
        invoice_payment_pending[:organisation_id] = invoice.organisation_id
        invoice_payment_pending[:is_active] = true

        if invoice_payment_pending.save
          invoice_payment_pending_ids << invoice_payment_pending.id.to_s
        end
      end

      Analytics::Financial::PayerPaymentJob.perform_later(invoice_payment_received_ids, invoice_payment_pending_ids, inactive_invoice_payment_received_ids, inactive_invoice_payment_pending_ids, invoice.id.to_s)
      Analytics::Financial::PaymentModeJob.perform_later(invoice_payment_received_ids, inactive_invoice_payment_received_ids, invoice.id.to_s)
    end
  end
end
