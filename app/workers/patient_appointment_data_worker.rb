class PatientAppointmentDataWorker
  include Sidekiq::Worker

  def perform(template_id)
  end
end
