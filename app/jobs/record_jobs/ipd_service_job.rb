class IpdServiceJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    # IpdService::Records.new(args[0],args[1]).create
  end
end
