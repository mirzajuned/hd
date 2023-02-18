class MisJobs::Administrative::UserSessionAuditJob < ActiveJob::Base
  queue_as :urgent

  def perform(params)
    Mis::AdministrativeReports::UserSessionAuditService.log(params)
  end
end
