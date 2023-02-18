class Analytics::Financial::PaymentModeResetService
  def self.call(payment_detail_id, payment_type)
    payment_detail = Invoice::PaymentReceived.find_by(id: payment_detail_id)
    mode_of_payment = (payment_detail.present? && payment_detail.mode_of_payment.present?) ? payment_detail.mode_of_payment : 'cash'

    if payment_detail.present?
      payment_mode = Analytics::Financial::PaymentMode.find_by(date: payment_detail.date, type: payment_detail.invoice_type.to_s.downcase, facility_id: payment_detail.facility_id)

      if payment_mode.present?
        payment_mode_field = "payment_mode.#{mode_of_payment.gsub(' ', '_').downcase}"
        eval("#{payment_mode_field} = #{payment_mode_field} - #{payment_detail.amount.to_f}")
        payment_mode.save
      end
    end
  end
end
