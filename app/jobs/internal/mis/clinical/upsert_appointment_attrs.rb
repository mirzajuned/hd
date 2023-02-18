class Internal::Mis::Clinical::UpsertAppointmentAttrs < ActiveJob::Base

  def perform(mandatory, optional = {}, others = {})
    Rails.logger.info("Internal::Mis::Clinical::UpsertAppointmentAttrs :: entering")

    Rails.logger.info("Internal::Mis::Clinical::UpsertAppointmentAttrs :: mandatory fields :: #{mandatory}")
    Rails.logger.info("Internal::Mis::Clinical::UpsertAppointmentAttrs :: optional fields  :: #{optional}")
    Rails.logger.info("Internal::Mis::Clinical::UpsertAppointmentAttrs :: others fields  :: #{others}")
    appointment_id = "#{mandatory['appointment_id'].to_s}"
    Rails.logger.info("Internal::Mis::Clinical::UpsertAppointmentAttrs :: appointment_id var  :: #{appointment_id}")
    ::Mis::NewClinicalReports::Opd::AppointmentDetailsService.call(appointment_id)

    Rails.logger.info("Internal::Mis::Clinical::UpsertAppointmentAttrs :: existing")
  end

end
