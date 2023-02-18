class MisJobs::Clinical::PatientProcedureJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Mis::NewClinicalReports::StructureProcedureDetails.call(args[0], args[1], args[2])
  end

end