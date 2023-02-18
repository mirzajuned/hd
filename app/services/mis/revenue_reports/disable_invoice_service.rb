module Mis::RevenueReports
  class DisableInvoiceService
    class << self
      def call(invoice_id, mis_logger = nil)
        mis_logger ||= Logger.new("#{Rails.root}/log/mis_logger.log")
        f_mis_revenue = Finance::ReportData.find_by(invoice_id: invoice_id)
        if f_mis_revenue.present?
          if f_mis_revenue.is_advance == true && f_mis_revenue.has_refund == false
            invoice = AdvancePayment.find_by(id: invoice_id)
          elsif f_mis_revenue.has_refund == false
            invoice = Invoice.find_by(id: invoice_id)
          end
          unless invoice.present?
            mis_logger.info(
              " ==== Cancel not found with invoice_id: #{invoice_id}"
            )
          end
          return unless invoice.present?
          canceled_by = invoice.try(:canceled_by_id) || invoice.try(:canceled_by)
          cancelled_invoice_hash = { canceled_by: canceled_by,
                                     cancel_date: invoice.try(:cancel_date),
                                     refund_amount: invoice.try(:refund_amount),
                                     refund_reason: invoice.try(:refund_reason) }
          # invoice_type = f_mis_revenue.receipt_display_fields['type']
          f_mis_revenue.is_cancelled = invoice.try(:is_canceled) || false
          f_mis_revenue.cancelled_invoice_fields = cancelled_invoice_hash
          f_mis_revenue.receipt_updated_at = invoice.updated_at
          f_mis_revenue.receipt_display_fields['is_refunded'] = invoice.is_refunded
          f_mis_revenue.save!
          # Mis::RevenueReports::ReturnInvoiceService.call(invoice_id, mis_logger)
        else
          mis_logger.info(" === ReportData for canceled invoice was not created for invoice id: #{invoice_id}")
        end
      # rescue StandardError => e
      #   mis_logger.error(" === error in DisableInvoiceService :: #{e.inspect}")
      end
    end
  end
end
