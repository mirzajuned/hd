class InvoiceJobs::PatientUpdateJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Mis::RevenueReports::UpdatePatientService.call(args[0])
  end
end
