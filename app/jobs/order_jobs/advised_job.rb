class OrderJobs::AdvisedJob < ActiveJob::Base
  queue_as :urgent

  def perform(case_sheet_id, current_user_id, current_facility_id)
    Orders::Advised::CreateService.create_orders_from_case_sheet(case_sheet_id, current_user_id, current_facility_id)
  end
end
