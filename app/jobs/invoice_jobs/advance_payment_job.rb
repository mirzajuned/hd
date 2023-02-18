class InvoiceJobs::AdvancePaymentJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Mis::RevenueReports::AdvancePaymentService.call(args[0])
  end
end
