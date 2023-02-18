class MisJobs::Finance::ItemWiseBillTypeJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    invoice_id = args[0]
    Mis::RevenueReports::ManageItemWiseBillTypeService.call(invoice_id)
  end

end
