class Analytics::Financial::PayerPaymentJob < ActiveJob::Base
  queue_as :urgent
  def perform(invoice_payment_received_ids, invoice_payment_pending_ids, inactive_invoice_payment_received_ids, inactive_invoice_payment_pending_ids, invoice_id)
    invoice_payment_receiveds = Invoice::PaymentReceived.where(:id.in => invoice_payment_received_ids)
    invoice_payment_pendings = Invoice::PaymentPending.where(:id.in => invoice_payment_pending_ids)

    inactive_invoice_payment_receiveds = Invoice::PaymentReceived.where(:id.nin => inactive_invoice_payment_received_ids, invoice_id: invoice_id, is_active: false)
    inactive_invoice_payment_pendings = Invoice::PaymentPending.where(:id.nin => inactive_invoice_payment_pending_ids, invoice_id: invoice_id, is_active: false)

    invoice_payment_receiveds.each do |payment_received|
      payer_master = PayerMaster.find_by(id: payment_received.received_from)

      if payer_master.present?
        payer_payment = Analytics::Financial::PayerPayment.find_by(date: payment_received.date, payer_master_id: payment_received.received_from, facility_id: payment_received.facility_id) || Analytics::Financial::PayerPayment.new

        if payer_payment.present?
          payer_payment.date = payment_received.date
          payer_payment.payer_master_id = payer_master.id
          payer_payment.contact_name = payer_master.display_name
          payer_payment.currency_id = payment_received.currency_id
          payer_payment.currency_symbol = payment_received.currency_symbol
          payer_payment.facility_id = payment_received.facility_id
          payer_payment.organisation_id = payment_received.organisation_id

          if payment_received.invoice_type == "Opd"
            payer_payment.received_opd_total = payer_payment.received_opd_total + payment_received.amount
            payer_payment.received_ipd_total = payer_payment.received_ipd_total
          elsif payment_received.invoice_type == "Ipd"
            payer_payment.received_opd_total = payer_payment.received_opd_total
            payer_payment.received_ipd_total = payer_payment.received_ipd_total + payment_received.amount
          end

          payer_payment.received_total = payer_payment.received_opd_total + payer_payment.received_ipd_total
          payer_payment.opd_total = payer_payment.received_opd_total + payer_payment.pending_opd_total
          payer_payment.ipd_total = payer_payment.received_ipd_total + payer_payment.pending_ipd_total
          payer_payment.total = payer_payment.opd_total + payer_payment.ipd_total

          payer_payment.save
        end
      end
    end

    invoice_payment_pendings.each do |payment_pending|
      payer_master = PayerMaster.find_by(id: payment_pending.received_from)

      if payer_master.present?
        payer_payment = Analytics::Financial::PayerPayment.find_by(date: payment_pending.date, payer_master_id: payment_pending.received_from, facility_id: payment_pending.facility_id) || Analytics::Financial::PayerPayment.new

        if payer_payment.present?
          payer_payment.date = payment_pending.date
          payer_payment.payer_master_id = payer_master.id
          payer_payment.contact_name = payer_master.display_name
          payer_payment.currency_id = payment_pending.currency_id
          payer_payment.currency_symbol = payment_pending.currency_symbol
          payer_payment.facility_id = payment_pending.facility_id
          payer_payment.organisation_id = payment_pending.organisation_id

          if payment_pending.invoice_type == "Opd"
            payer_payment.pending_opd_total = payer_payment.pending_opd_total + payment_pending.amount
            payer_payment.pending_ipd_total = payer_payment.pending_ipd_total
          elsif payment_pending.invoice_type == "Ipd"
            payer_payment.pending_opd_total = payer_payment.pending_opd_total
            payer_payment.pending_ipd_total = payer_payment.pending_ipd_total + payment_pending.amount
          end
          payer_payment.pending_total = payer_payment.pending_opd_total + payer_payment.pending_ipd_total
          payer_payment.opd_total = payer_payment.received_opd_total + payer_payment.pending_opd_total
          payer_payment.ipd_total = payer_payment.received_ipd_total + payer_payment.pending_ipd_total
          payer_payment.total = payer_payment.opd_total + payer_payment.ipd_total

          payer_payment.save
        end
      end
    end

    inactive_invoice_payment_receiveds.each do |payment_received|
      Analytics::Financial::PayerPaymentResetService.call(payment_received.id.to_s, "Invoice::PaymentReceived")
    end
    inactive_invoice_payment_pendings.each do |payment_pending|
      Analytics::Financial::PayerPaymentResetService.call(payment_pending.id.to_s, "Invoice::PaymentPending")
    end
  end
end
