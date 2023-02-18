class Inventory::RefundPayments::CreateService
  def self.call(invoice, reason, current_user, return_from , *data)
    # current_user = User.find_by(id: user_id)
    refund_payment = RefundPayment.new
    if return_from == 'order'
      inventory_invoice = Invoice::InventoryOrder.find_by(id: invoice.id)
      refund_payment_type = 'Refund Against Order'
      refund_payment.amount = invoice.advance_payment || 0
      refund_payment.invoice_received_amount = invoice.advance_payment || 0
      refund_payment.invoice_total_amount = invoice.net_amount
      refund_payment.cash = invoice.advance_payment
      refund_payment.order_id = invoice.id
      refund_payment.return_charges = 0.0
      unless data.present?
        refund_payment.mode_of_payment = invoice.mode_of_payment || 'Cash'
      else
        refund_payment.mode_of_payment = data[0][:mode_of_payment]
        if data[0][:mode_of_payment] == "Others"
          refund_payment.other_transaction_id = data[0][:transaction_id]
          refund_payment.other_note = data[0][:transaction_note]
        end
      end
      refund_payment.order_number = inventory_invoice&.order_number
    else
      inventory_invoice = Invoice::InventoryInvoice.find_by(id: invoice.invoice_id)
      refund_payment_type = 'Refund Against Bill'
      refund_payment.amount = invoice.return_amount || 0
      refund_payment.invoice_received_amount = invoice.invoice_received_amount || 0
      refund_payment.invoice_total_amount = invoice.invoice_total_amount
      refund_payment.cash = invoice.return_amount
      refund_payment.invoice_id = invoice.invoice_id
      refund_payment.return_charges = invoice.return_charges
      unless data.present?
        refund_payment.mode_of_payment = invoice.mode_of_payment || 'Cash'
      else
        refund_payment.mode_of_payment = data[0][:mode_of_payment]
        if data[0][:mode_of_payment] == "Others"
          refund_payment.other_transaction_id = data[0][:transaction_id]
          refund_payment.other_note = data[0][:transaction_note]
        end
      end
      refund_payment.bill_number = inventory_invoice&.bill_number
      refund_payment.refund_display_id = invoice&.return_bill_number
    end
    refund_payment.payment_date = Date.current
    refund_payment.refund_type = 'refund'
    refund_payment.reason = reason
    refund_payment.currency_symbol = invoice.currency_symbol
    refund_payment.currency_id = invoice.currency_id

    refund_payment.payment_time = Time.current
    refund_payment.bkp_refund_display_id = CommonHelper.get_refund_identifier(current_user)
    refund_payment.type = invoice.department_name
    refund_payment.department_id = invoice.department_id
    refund_payment.department_name = invoice.department_name
    refund_payment.refund_state = 'None'
    refund_payment.user_id = invoice.user_id
    refund_payment.facility_id = invoice.facility_id
    refund_payment.organisation_id = invoice.organisation_id
    refund_payment.specialty_id = invoice.specialty_id
    refund_payment.patient_id = invoice.patient_id
    refund_payment.store_id = invoice.store_id
    refund_payment.refund_payment_type = refund_payment_type
    # Added by Dhara on 2021-07-27
    # Inventory Invoice will be nil in case return is made against patient
    refund_payment.is_canceled = inventory_invoice&.is_canceled
    refund_payment.cancel_date = inventory_invoice&.cancel_date
    refund_payment.canceled_by_id = inventory_invoice&.canceled_by_id
    refund_payment.canceled_by = inventory_invoice&.canceled_by
    refund_payment.save

    region_master_id = Facility.find_by(id: invoice.try(:facility_id)).try(:region_master_id)

    # refund_display_id = SequenceManagers::GenerateSequenceService.call('refund_payment', refund_payment.id.to_s, {organisation_id: invoice.organisation_id.to_s, facility_id: invoice.facility_id.to_s, region_id: region_master_id.to_s, department_id: invoice.department_id})
    # refund_payment.update(refund_display_id: refund_display_id)

    refund_payment.id
  end
end
