class MisJobs::Clinical::ExtractDiagnosesJob < ActiveJob::Base
	queue_as :urgent

	def perform(*args)
		record_id = args[0]
		from_department = args[1]
		created_from_form_name = args[2]
		Mis::Clinical::ExtractDiagnosesWorker.new(record_id, from_department, created_from_form_name).call
	end

end
