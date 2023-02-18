class Analytics::Financial::PayerPaymentResetService
  def self.call(payment_detail_id, payment_type)
    payment_detail = eval(payment_type).find_by(id: payment_detail_id)
    if payment_detail.present?
      payer_payment = Analytics::Financial::PayerPayment.find_by(date: payment_detail.date, payer_master_id: payment_detail.received_from, facility_id: payment_detail.facility_id)

      if payer_payment.present?
        payment_detail_amount = payment_detail.amount

        if payment_type == "Invoice::PaymentReceived"
          if payment_detail.invoice_type == "Opd"
            payer_payment.received_opd_total = payer_payment.received_opd_total - payment_detail_amount
            payer_payment.opd_total = payer_payment.opd_total - payment_detail_amount
          elsif payment_detail.invoice_type == "Ipd"
            payer_payment.received_ipd_total = payer_payment.received_ipd_total - payment_detail_amount
            payer_payment.ipd_total = payer_payment.ipd_total - payment_detail_amount
          end
          payer_payment.received_total = payer_payment.received_total - payment_detail_amount
        elsif payment_type == "Invoice::PaymentPending"
          if payment_detail.invoice_type == "Opd"
            payer_payment.pending_opd_total = payer_payment.pending_opd_total - payment_detail_amount
            payer_payment.opd_total = payer_payment.opd_total - payment_detail_amount
          elsif payment_detail.invoice_type == "Ipd"
            payer_payment.pending_ipd_total = payer_payment.pending_ipd_total - payment_detail_amount
            payer_payment.ipd_total = payer_payment.ipd_total - payment_detail_amount
          end
          payer_payment.pending_total = payer_payment.pending_total - payment_detail_amount
        end

        payer_payment.total = payer_payment.total - payment_detail_amount
        payer_payment.save
      end
    end
  end
end
