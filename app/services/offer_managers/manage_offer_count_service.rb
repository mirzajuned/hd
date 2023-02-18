module OfferManagers::ManageOfferCountService
  def self.call(offer_manager_id)
    offer_manager = OfferManager.find_by(id: offer_manager_id)
    offer_manager.inc(redeemed_count: 1)
  end
  # EOf self.call
end