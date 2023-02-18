class SmsJob < ActiveJob::Base
  queue_as :sms

  def perform(*args)
    SmsWorker.new(args[0], args[1], args[2]).call
  end
end
