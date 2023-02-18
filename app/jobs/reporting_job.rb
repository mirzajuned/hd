class ReportingJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    # first argument will be type of worker to be called eg: appointment_report_worker,invoice_report_worker
    # Create worker file and Intialize workers here with parameters
    # search get_daily_report for places to call apointment,ot,admission related job in project
  end
end
