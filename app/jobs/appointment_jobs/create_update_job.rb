class AppointmentJobs::CreateUpdateJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    # args[0] contains type of type of service to be called
    # args[1] contains appointment_id
    AppointmentWorker.new(args[0], args[1]).call
  end
end
