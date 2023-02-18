class DilatePatientJob < ActiveJob::Base
  queue_as :urgent
  def perform(*args)
    appointment = Appointment.find_by(id: args[0])
    end_time = appointment.dilation_start_time + 60.minutes
    appointment.update_attributes(dilation_end_time: end_time)
  end
end
