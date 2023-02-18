class OfferManagerJobs::ManageOfferCountJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    offer_manager_id = args[0]
    OfferManagers::ManageOfferCountService.call(offer_manager_id)
  end

end
