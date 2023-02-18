class OutreachJobs::CampReferenceUpdateJob < ActiveJob::Base
  queue_as :urgent

  def perform(_id, params)
    new_params = params["camp"]
    @camp = Camp.find_by(id: _id)
    @subreferral = SubReferralType.find_by(camp_unique_id: @camp.username)
    @subreferral.update_attributes(city: new_params["city"], location: new_params["area"],
                                   name: new_params["camp_name"], camp_date: new_params["camp_date"])
  end
end
