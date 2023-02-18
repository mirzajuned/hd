module Mis::RevenueReports
  class ReturnInvoiceService
    class << self
      # rubocop:disable Metrics/MethodLength
      def call(refund_id, refund_from, mis_logger = nil)
        $mis_logger ||= Logger.new("#{Rails.root}/log/mis_logger.log")
        if refund_from == 'receipt'
          invoices = RefundPayment.where(id: refund_id)
        elsif refund_from == 'inventory'
          invoices = Inventory::Transaction::Return.where(id: refund_id)
        end
        invoices.each do |invoice|
          organisation_id = invoice.organisation_id.to_s
          facility_id = invoice.facility_id.to_s
          department_id = invoice.department_id
          user_id = invoice.try(:user_id).to_s
          user = User.find_by(id: user_id)
          user_name = user.try(:fullname)
          is_deleted = invoice.try(:is_deleted) || false

          patient_id = invoice.patient_id.to_s
          patient_name = Patient.find_by(id: patient_id).try(:fullname)
          refund_invoice_fields_hash = {}
          if refund_from == 'receipt' && invoice.invoice_id.present?
            refund_invoice_fields_hash.merge!(opd_ipd_return(invoice))
          elsif refund_from == 'receipt' && invoice.advance_payment_id.present?
            refund_invoice_fields_hash.merge!(advance_return(invoice))
          elsif refund_from == 'inventory'
            refund_invoice_fields_hash.merge!(inventory_return(invoice))
          else
            # info from RefundPayment without invoice_id and advance_invoice_id
            refund_invoice_fields_hash.merge!(refund_payment_return(invoice))
          end
          refund_invoice_fields_hash.merge!({
                                           department_id: department_id,
                                           facility_id: facility_id,
                                           organisation_id: organisation_id,
                                           is_deleted: invoice.try(:is_deleted),
                                           invoice_id: invoice.id.to_s
                                         })

          invoice_hash = {
            department_id: department_id, facility_id: facility_id, organisation_id: organisation_id
          }
          patient_hash = user_hash = {}
          has_logs = has_advance_history = false
          receipt_logs = advance_history = []
          if invoice.invoice_id.present?
            # invoice_hash = Invoice::GetBillDetailsService.call(invoice.invoice_id)
            receipt = Finance::ReportData.find_by(invoice_id: invoice.invoice_id)
            if receipt.present?
              invoice_hash = receipt.receipt_display_fields
              patient_hash = receipt.patient_display_fields
              user_hash = receipt.user_display_fields
              has_logs = receipt.has_logs
              receipt_logs = receipt.receipt_logs
            else
              $mis_logger.info("============ return invoice service: receipt not found with invoice id: #{invoice.invoice_id}")
            end
          elsif refund_from == 'receipt' && invoice.advance_payment_id.present?
            receipt = Finance::ReportData.find_by(invoice_id: invoice.advance_payment_id)
            if receipt.present?
              invoice_hash = receipt.receipt_display_fields
              patient_hash = receipt.patient_display_fields
              user_hash = receipt.user_display_fields
              has_advance_history = receipt.has_advance_history
              advance_history = receipt.advance_history
            else
              $mis_logger.info("============ return invoice service: receipt not found with advance id: #{invoice.advance_payment_id}")
            end
          end

          # refund history
          refund_history = []
          has_refund_history = false
          # NOTE: not saving history in RefundPayment or Inventory::Transaction::Return rn

          # filter_fields
          filter_fields_hash = { organisation_id: organisation_id, facility_id: facility_id,
                                 user_id: user_id }
          # EOF filter_fields

          # search_fields
          search_fields_hash = { patient_name: patient_name, user_name: user_name }
          # EOF search_fields

          f_mis_revenue = Finance::ReportData.find_or_create_by(
            invoice_id: invoice.id.to_s, organisation_id: organisation_id, facility_id: facility_id
          )

          f_mis_revenue.has_refund = true
          f_mis_revenue.is_refunded = invoice.is_refunded
          f_mis_revenue.is_cancelled = invoice.is_canceled
          f_mis_revenue.is_advance = receipt.try(:is_advance) || false
          f_mis_revenue.receipt_created_at = invoice.created_at
          f_mis_revenue.receipt_updated_at = invoice.updated_at
          f_mis_revenue.receipt_display_fields = invoice_hash
          f_mis_revenue.patient_display_fields = patient_hash
          f_mis_revenue.user_display_fields = user_hash

          f_mis_revenue.refund_invoice_fields = refund_invoice_fields_hash
          f_mis_revenue.has_refund_history = has_refund_history
          f_mis_revenue.refund_history = refund_history

          f_mis_revenue.has_logs = has_logs
          f_mis_revenue.receipt_logs = receipt_logs
          f_mis_revenue.has_advance_history = has_advance_history
          f_mis_revenue.advance_history = advance_history

          f_mis_revenue.filter_fields = filter_fields_hash
          f_mis_revenue.search_fields = search_fields_hash
          f_mis_revenue.is_deleted = is_deleted
          f_mis_revenue.save!
        end
      # rescue StandardError => e
      #   $mis_logger.error(" === error in ReturnInvoiceService :: #{e.inspect}")
      end

      # rubocop:enable Metrics/MethodLength

      def opd_ipd_return(invoice)
        refund_invoice_fields_hash = {
          return_invoice_number: invoice.refund_display_id, status: invoice.refund_state,
          return_date: invoice.refund_date, return_time: invoice.refund_time, 
          return_charges: invoice.try(:amount_remaining).to_f,
          invoice_received_amount: invoice.try(:invoice_received_amount).to_f, return_amount: invoice.amount.to_f,
          invoice_total_amount: invoice.invoice_total_amount.to_f, amount_remaining: invoice.amount_remaining.to_f,
          mode_of_payment: invoice.mode_of_payment, return_type: invoice.type, level: invoice.level,
          entered_by: invoice.try(:entered_by), patient_id: invoice.patient_id.to_s,
          user_id: invoice.user_id.to_s, return_history: invoice.refund_history, refund_reason: invoice.reason,
          invoice_settled_amount: invoice.invoice_settled_amount, canceled_by: invoice.canceled_by,
          canceled_by_id: invoice.canceled_by_id, cancel_date: invoice.cancel_date, refunded_by: invoice.refunded_by,
          refunded_by_id: invoice.refunded_by_id, refund_date: invoice.refund_date, refund_time: invoice.refund_time
        }
        refund_invoice_fields_hash
      end

      def advance_return(invoice)
        refund_invoice_fields_hash = {
          return_invoice_number: invoice.refund_display_id, status: invoice.refund_state,
          return_date: invoice.refund_date, return_time: invoice.refund_time, return_charges: invoice.amount_remaining.to_f,
          invoice_received_amount: invoice.try(:advance_total_amount).to_f, return_amount: invoice.amount.to_f,
          invoice_total_amount: invoice.advance_total_amount.to_f, amount_remaining: invoice.advance_remaining_amount.to_f,
          mode_of_payment: invoice.mode_of_payment, return_type: invoice.type, level: invoice.level,
          entered_by: invoice.try(:entered_by), patient_id: invoice.patient_id.to_s,
          user_id: invoice.user_id.to_s, return_history: invoice.refund_history, refund_reason: invoice.reason,
          invoice_settled_amount: invoice.invoice_settled_amount, canceled_by: invoice.canceled_by,
          canceled_by_id: invoice.canceled_by_id, cancel_date: invoice.cancel_date, refunded_by: invoice.refunded_by,
          refunded_by_id: invoice.refunded_by_id, refund_date: invoice.refund_date, refund_time: invoice.refund_time
        }
        refund_invoice_fields_hash
      end

      def refund_payment_return(invoice)
        refund_invoice_fields_hash = {
          return_invoice_number: invoice.refund_display_id, status: invoice.refund_state,
          return_date: invoice.payment_date, return_time: invoice.payment_time, return_charges: invoice.amount_remaining.to_f,
          return_amount: invoice.amount.to_f, mode_of_payment: invoice.mode_of_payment, return_type: invoice.type, level: invoice.level,
          entered_by: invoice.try(:entered_by), patient_id: invoice.patient_id.to_s,
          user_id: invoice.user_id.to_s, return_history: invoice.refund_history, refund_reason: invoice.reason
        }
        refund_invoice_fields_hash
      end

      def inventory_return(invoice)
        refund_invoice_fields_hash = {
          return_invoice_number: invoice.try(:return_bill_number), status: invoice.try(:status),
          return_date: invoice.return_date, return_time: invoice.return_time, return_charges: invoice.try(:return_charges).to_f,
          invoice_received_amount: invoice.try(:invoice_received_amount).to_f, 
          return_amount: invoice.return_amount.to_f, mode_of_payment: invoice.mode_of_payment,
          return_type: invoice.return_type, entered_by: invoice.entered_by,
          patient_id: invoice.patient_id.to_s, user_id: invoice.user_id.to_s,
          store_id: invoice.store_id.to_s, refund_reason: invoice.try(:note)
        }
        refund_invoice_fields_hash
      end
    end
  end
end
