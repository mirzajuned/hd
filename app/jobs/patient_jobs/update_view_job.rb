class PatientJobs::UpdateViewJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    # args[0] has type in [admission_list,ot_list,workflow_list,non_workflow_list,counsellor_list]
    # args[1] has patient_id
    UpdateViewWorker.new(args[0], args[1]).call
  end
end
