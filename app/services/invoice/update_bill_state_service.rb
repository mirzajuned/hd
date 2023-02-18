class Invoice::UpdateBillStateService
  class << self
    def call(invoice_id)
      invoice = Invoice.find_by(id: invoice_id)
      if invoice.net_amount.to_f > 0 && invoice.total_discount.to_f > 0
        invoice.is_paid_discounted = true
      elsif invoice.net_amount.to_f == 0  && invoice.total_discount.to_f > 0
        invoice.is_free_discounted = true
      elsif invoice.net_amount.to_f > 0 && invoice.total_discount.to_f == 0
        invoice.is_paid = true
      else
        invoice.is_free = true
      end

      invoice.migration = true
      invoice.is_migrated = true
      invoice.save
    rescue StandardError => e
      Rails.logger.error(" === Error in UpdateBillStateService : #{e.inspect}")
    end
  end
end
