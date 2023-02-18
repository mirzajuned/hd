class InvestigationStopJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    @inv_workflow = InvestigationWorkflow.where(state: 'advised')
    @inv_workflow.each do |inv_workflow|
      if DateTime.current - 3 > inv_workflow.updated_at
        # inv_workflow.patient_not_arrived

      end
    end
  end
end
