class DataForIpdJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    IpdDataWorker.new(args[0]).call
  end
end
