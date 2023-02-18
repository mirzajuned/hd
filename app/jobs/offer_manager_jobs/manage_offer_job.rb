class OfferManagerJobs::ManageOfferJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    offer_manager_id = args[0]
    department_ids = args[1]
    store_ids = args[2]
    OfferManagers::ManageOffersService.call(offer_manager_id, department_ids, store_ids)
  end

end
