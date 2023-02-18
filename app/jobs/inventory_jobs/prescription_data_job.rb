class InventoryJobs::PrescriptionDataJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Mis::PrescriptionConversionReports::ManagePrescriptionService.call(args[0], args[1])
  end
end
