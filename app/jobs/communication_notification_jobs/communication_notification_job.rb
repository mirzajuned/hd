class CommunicationNotificationJob < ActiveJob::Base
  queue_as :notification

  def perform(*args)
    CommunicationNotificationWorker.new(args[0], args[1], args[2]).call
  end
end
