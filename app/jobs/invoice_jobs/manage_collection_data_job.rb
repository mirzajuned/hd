class InvoiceJobs::ManageCollectionDataJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Mis::CollectionReports::ManageCollectionService.call(args[0], args[1])
  end
end
