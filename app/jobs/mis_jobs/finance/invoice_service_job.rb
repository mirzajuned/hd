class MisJobs::Finance::InvoiceServiceJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    invoice_id = args[0]
    Mis::RevenueReports::ManageInvoiceServiceWiseService.call(invoice_id)
  end

end
