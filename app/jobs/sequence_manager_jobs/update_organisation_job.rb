class SequenceManagerJobs::UpdateOrganisationJob < ActiveJob::Base
  queue_as :urgent

  def perform(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    sequences = SequenceManager.where(organisation_id: organisation_id)
    sequences.update_all(organisation_abbreviation: organisation.try(:identifier_prefix))
  end
end