class FacilityJobs::UpdateQmSettingJob < ActiveJob::Base
  queue_as :urgent

  def perform(facility_id, facility_settings)
    is_qm_enabled = facility_settings[:queue_management]
    ocw = OpdClinicalWorkflow.where(:appointmentdate.gt => Date.current, facility_id: facility_id)
    ocw.update_all(is_qm_enabled: is_qm_enabled)
  end
end
