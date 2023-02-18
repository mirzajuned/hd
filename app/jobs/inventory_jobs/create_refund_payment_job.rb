class InventoryJobs::CreateRefundPaymentJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    invoice_id = args[0]
    reason = args[1]
    user = User.find_by(id: args[2])
    invoice_return = Inventory::Transaction::Return.find_by(id: invoice_id)
    Inventory::RefundPayments::CreateService.call(invoice_return, reason, user, 'invoice')
  end
end
