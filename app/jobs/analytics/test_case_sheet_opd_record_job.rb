class Analytics::TestCaseSheetOpdRecordJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Analytics::ClinicalData::CreateUpdateService.call(args[0], args[1], args[2])
  end
end
