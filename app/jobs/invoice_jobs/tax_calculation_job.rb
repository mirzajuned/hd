class TaxCalculationJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    TaxCalculationWorker.new(args[0], args[1]).call
  end
end

# args[0] contains invoice _id
# args[1] contains request_path [tax_collected_details, tax_recollected_details]
