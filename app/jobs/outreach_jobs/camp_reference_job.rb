class OutreachJobs::CampReferenceJob < ActiveJob::Base
  queue_as :urgent

  def perform(_id, user_id)
    @camp = Camp.find_by(id: _id)
    @subreferral = SubReferralType.new(name: @camp.camp_name, comment: 'auto generated subreferral',
                                       facility_ids: [@camp.facility_id.to_s], camp_date: @camp.camp_date,
                                       location: @camp.area, city: @camp.city, state: @camp.state,
                                       referral_type_id: "FS-RT-0006", organisation_id: @camp.organisation_id,
                                       user_id: user_id, camp_unique_id: @camp.username, is_disabled: true)

    @subreferral.save!
  end
end
