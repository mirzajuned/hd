class CreatePricingMasterJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    PricingMasters::CreateService.call(args[0], args[1])
  end
end
