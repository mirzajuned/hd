class AppointmentTypeJobs::AppointmentTypeJob < ActiveJob::Base
  queue_as :urgent

  def perform(facility_id, organisation_id)
    if facility_id.present? && organisation_id.present?

      # creating default facility appointment type
      appointment_types = OrganisationAppointmentType.where(organisation_id: organisation_id)
      appointment_types.each do |org_ap_type|
        AppointmentType.new.tap do |appointment_type|
          appointment_type.label = org_ap_type.label
          appointment_type.duration = org_ap_type.duration
          appointment_type.background = org_ap_type.background
          appointment_type.is_active = org_ap_type.is_active
          appointment_type.is_default = org_ap_type.is_default
          appointment_type.organisation_id = organisation_id
          appointment_type.facility_id = facility_id
          appointment_type.specialty_ids = org_ap_type.specialty_ids
          appointment_type.organisation_appointment_type_id = org_ap_type.id
          appointment_type.version = "after_orange"
          appointment_type.comment = ""
          appointment_type.save!
        end
      end
    end
  end
end
