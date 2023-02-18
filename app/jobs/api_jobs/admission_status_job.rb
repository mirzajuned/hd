class ApiJobs::AdmissionStatusJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    admission_id = args[0]
    client = args[1]
    facility_id = args[2]
    status = args[3]
    dischargetime = args[4]
    ApiIntegration::AdmissionStatusData.update(admission_id, client, facility_id.to_s, status, dischargetime)
  end
end
