class OpdRecordJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    OpdRecordWorker.new(args[0]).call
  end
end
