class OrganisationContractJobs::ActivateJob < ActiveJob::Base
  queue_as :urgent

  def perform(id, organisation_id)
    organisation_contract = OrganisationContract.find_by(id: id)
    return if organisation_contract.nil? || organisation_contract.start_date != Date.today

    organisation_contract.set(active: true)

    active_contract = OrganisationContract.find_by(organisation_id: organisation_id, active: true)
    return unless active_contract

    active_contract.end_date = organisation_contract.start_date - 1.day if active_contract.end_date >= Date.today
    active_contract.active = false

    active_contract.save
  rescue StandardError => e
    e.message
  end
end
