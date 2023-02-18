class ApiJobs::AppointmentDataJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    method_type = args[0]
    appointment_id = args[1]
    client = args[2]

    appointment_data_service = ApiIntegration::AppointmentData.new

    appointment_data_service.send(method_type.to_sym, appointment_id, client)
  end
end
