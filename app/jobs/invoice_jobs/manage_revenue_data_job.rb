class InvoiceJobs::ManageRevenueDataJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Mis::RevenueReports::ManageRevenueService.call(args[0])
  end
end
