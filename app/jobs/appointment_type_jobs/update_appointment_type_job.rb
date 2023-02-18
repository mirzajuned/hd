class AppointmentTypeJobs::UpdateAppointmentTypeJob < ActiveJob::Base
  queue_as :urgent

  def perform(organisation_id)
    # facility = Facility.find_by(id:facility_id)
    # organisation = Organisation.find_by(id:facility.organisation.id) if facility.present?

    if organisation_id.present?
      # creating default facility appointment type
      organisation_appointment_type = OrganisationAppointmentType.where(organisation_id: organisation_id)
      all_facilities = Facility.where(organisation_id: organisation_id).pluck(:id)

      organisation_appointment_type.each do |org_ap_type|
        all_facilities.each do |facility_id|
          facility_appointment_type = AppointmentType.find_or_create_by(organisation_appointment_type_id: org_ap_type.id, facility_id: facility_id)

          facility_appointment_type.update_attributes(label: org_ap_type.label, duration: org_ap_type.duration, background: org_ap_type.background,
                                                      is_active: org_ap_type.is_active, is_default: org_ap_type.is_default, organisation_id: organisation_id, facility_id: facility_id, specialty_ids: org_ap_type.specialty_ids)
        end
      end

    end
  end
end
