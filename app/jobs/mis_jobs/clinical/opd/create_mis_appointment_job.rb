class MisJobs::Clinical::Opd::CreateMisAppointmentJob < ActiveJob::Base
	queue_as :urgent

	def perform(appointment_id)
		appointment = AppointmentListView.find_by(appointment_id: appointment_id)
		Mis::NewClinicalReports::Opd::AppointmentDetailsService.call(appointment_id)
	end
end
