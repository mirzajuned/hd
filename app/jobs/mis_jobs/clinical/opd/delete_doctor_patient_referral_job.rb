class MisJobs::Clinical::Opd::DeleteDoctorPatientReferralJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Mis::ClinicalReports::Opd::DeleteDoctorPatientReferralSummaryService.call(args[0])
  end

end