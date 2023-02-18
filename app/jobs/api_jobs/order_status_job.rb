class ApiJobs::OrderStatusJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    visit_type = args[0]
    visit_id = args[1]
    client = args[2]
    current_facility_id = args[3]
    investigation = args[4]

    if investigation.present?
      ApiIntegration::OrderData.update_investigation_performed(visit_type, visit_id, client, current_facility_id, investigation)
    else
      ApiIntegration::OrderData.update(visit_type, visit_id, client, current_facility_id)
      ApiIntegration::OrderData.create(visit_type, visit_id, client, current_facility_id)
    end
  end
end
