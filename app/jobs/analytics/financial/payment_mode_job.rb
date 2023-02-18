class Analytics::Financial::PaymentModeJob < ActiveJob::Base
  queue_as :urgent
  def perform(invoice_payment_received_ids, inactive_invoice_payment_received_ids, invoice_id)
    invoice_payment_receiveds = Invoice::PaymentReceived.where(:id.in => invoice_payment_received_ids)
    inactive_invoice_payment_receiveds = Invoice::PaymentReceived.where(:id.nin => inactive_invoice_payment_received_ids, invoice_id: invoice_id, is_active: false)

    invoice_payment_receiveds.each do |payment_received|
      payment_mode = Analytics::Financial::PaymentMode.find_by(date: payment_received.date, type: payment_received.invoice_type.to_s.downcase, facility_id: payment_received.facility_id.to_s) || Analytics::Financial::PaymentMode.new

      if payment_mode.present?
        payment_mode.date = payment_received.date
        payment_mode.currency_id = payment_received.currency_id
        payment_mode.currency_symbol = payment_received.currency_symbol
        payment_mode.facility_id = payment_received.facility_id
        payment_mode.organisation_id = payment_received.organisation_id

        if payment_received.invoice_type == "Opd"
          payment_mode.type = "opd"
          payment_mode.type_id = "485396012"
        elsif payment_received.invoice_type == "Ipd"
          payment_mode.type = "ipd"
          payment_mode.type_id = "486546481"
        end

        if payment_received.mode_of_payment.present?
          payment_mode_field = "payment_mode.#{payment_received.mode_of_payment.to_s.gsub(' ', '_').downcase}"
        else
          payment_mode_field = "payment_mode.cash"
        end
        eval("#{payment_mode_field} = #{payment_mode_field} + #{payment_received.amount.to_f}")

        payment_mode.save
      end
    end

    inactive_invoice_payment_receiveds.each do |payment_received|
      Analytics::Financial::PaymentModeResetService.call(payment_received.id.to_s, "Invoice::PaymentReceived")
    end
  end
end
