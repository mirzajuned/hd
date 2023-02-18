class Invoice::CreateOrderNumberService
  class << self
    def call(order)
      order.payment_received_breakups.try(:each).with_index do |payment_received_breakup, index|
        count = index + 1
        if count >= 1 && count < 10
          counter = "0" + "#{count}"
        end
        receipt_id = "#{order.order_number}" + "-" + "#{counter}"
        payment_received_breakup.update(receipt_id: receipt_id)
      end
    end
  end
end