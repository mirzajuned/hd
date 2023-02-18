class InvoiceJobs::CancelReturnInvoiceJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    if args[1] == 'cancel'
      Mis::RevenueReports::DisableInvoiceService.call(args[0])
    elsif args[1] == 'return'
      Mis::RevenueReports::ReturnInvoiceService.call(args[0], args[2])
    end
  end
end
