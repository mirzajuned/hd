class MisFilterJobs::ManageFiltersJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Mis::ReportFilters::ManageFiltersService.call(args[0], args[1], args[2])
  end
end
