class OpticalEmail < ActiveJob::Base
  queue_as :delayed
  def perform(*args)
    @email_body = args[0]
    @email_id = args[1]
    OpticalMailer.customer_notification(@email_body, @email_id).deliver_now
  end
end
