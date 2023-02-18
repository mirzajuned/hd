class MisJobs::Clinical::Opd::ExtractDoctorPatientReferralJob < ActiveJob::Base
	queue_as :urgent

	def perform(*args)
		record_id = args[0]
		Mis::Clinical::Opd::ExtractDoctorPatientReferralWorker.new(record_id).call
	end

end