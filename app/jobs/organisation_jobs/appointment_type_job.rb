class OrganisationJobs::AppointmentTypeJob < ActiveJob::Base
  queue_as :urgent

  def perform(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)

    if organisation.present?
      # creating default organisation appointment type
      facility = organisation.facilities.first
      OrganisationAppointmentType.create!(appointment_types_data(facility.specialty_ids, organisation))
    end
  end

  private

  def appointment_types_data(specialty_ids, organisation)
    data = [{ label: "New", duration: 10, background: "#93FF33", is_active: true, is_default: true, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 10 },
            { label: "Review", duration: 10, background: "#ff0000", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 11 },
            { label: "Doctor Review", duration: 10, background: "#33FFD7", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 12 },
            { label: "Post OP", duration: 10, background: "#FF33AC", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 13 },
            { label: "Re visit", duration: 10, background: "#4C1130", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 14 },
            { label: "Follow up", duration: 10, background: "#6AA84F", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 15 }]

    if specialty_ids.include?("309988001")
      extra_app_types = [{ label: "PMT", duration: 10, background: "#3380FF", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 4 }, { label: "Investigation", duration: 10, background: "#000000", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 5 }, { label: "Surgery", duration: 10, background: "#fbff00", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 6 }, { label: "LASER", duration: 10, background: "#2e00ee", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 7 }, { label: "Referral", duration: 10, background: "#660000", is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: [specialty_ids[0]], default_set: true, s_no: 8 }]

      extra_app_types.each do |appointment_type|
        data << appointment_type
      end
    end

    return data
  end
end
