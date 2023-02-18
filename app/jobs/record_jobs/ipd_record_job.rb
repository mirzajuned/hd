class IpdRecordJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    IpdRecordWorker.new(args[0], args[1], args[2]).call
  end
end
