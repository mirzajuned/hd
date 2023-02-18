class MisJobs::Finance::BillTypeJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    invoice_id = args[0]
    Mis::RevenueReports::ManageBillTypeService.call(invoice_id)
  end

end
