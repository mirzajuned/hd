class AppointmentTypeJobs::AddOrganisationAppointmentCategoryJob < ActiveJob::Base
  queue_as :urgent

  def perform(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)

    if organisation.present?
      OrganisationAppointmentCategoryType.create!(
        [
          { label: "Free", background: "#EC2E06", is_active: true, organisation_id: organisation.id, specialty_ids: [organisation.specialty_ids[0]], default_set: true, s_no: 1, provided_by: "HG" },
          { label: "Paid", background: "#55FF33", is_active: true, organisation_id: organisation.id, specialty_ids: [organisation.specialty_ids[0]], default_set: true, s_no: 2, provided_by: "HG"  },
          { label: "Discounted", background: "#000000", is_active: true, organisation_id: organisation.id, specialty_ids: [organisation.specialty_ids[0]], default_set: true, s_no: 3, provided_by: "HG" }
        ]
      )

    end
  end
end
