class Inventory::Transactions::CreateReturnService
  class << self
    def call(invoice_id, _user_id, _user_name, type, data)
      return_invoice = Inventory::Transaction::Return.new
      if type == 'order'
        # for now here invoice_id is order_id, have to change in future
        inventory_invoice = Invoice::InventoryOrder.find_by(id: invoice_id)
        bill_number = inventory_invoice&.order_number
        return_invoice.order_id = inventory_invoice.id
        return_invoice.return_type = 'return_against_order'
      else
        inventory_invoice = Invoice::InventoryInvoice.find_by(id: invoice_id)
        bill_number = inventory_invoice.bill_number
        return_invoice.invoice_id = inventory_invoice.id
        return_invoice.return_type = 'return_against_invoice'
      end
      inventory_invoice_items = inventory_invoice.items
      store = Inventory::Store.find_by(id: inventory_invoice.store_id)
      bkp_return_bill_number = Invoice::InventoryReturnInvoicesHelper.increment_and_create_return_bill_number(
        inventory_invoice.store_id, inventory_invoice.facility_id
      )
      return_invoice.bkp_return_bill_number = bkp_return_bill_number
      # return_invoice.invoice_id = inventory_invoice.id
      return_invoice.status = 'Pending'
      return_invoice.note = inventory_invoice.refund_reason
      return_invoice.entered_by = inventory_invoice.entered_by
      return_invoice.entry_type = 'return'
      return_invoice.return_date = inventory_invoice.cancel_date
      if inventory_invoice.payment_completed
        return_invoice.total_cost = inventory_invoice.total - inventory_invoice.total_of_all_discount
        return_invoice.return_amount = inventory_invoice.net_amount
      else
        return_invoice.total_cost = inventory_invoice.payment_received
        return_invoice.return_amount = inventory_invoice.payment_received
      end
      # return_invoice.mode_of_payment = 'Cash'
      unless data.present?
        return_invoice.mode_of_payment = inventory_invoice.mode_of_payment || 'Cash'
      else
        return_invoice.mode_of_payment = data[:mode_of_payment]
        if data[:mode_of_payment] == "Others"
          return_invoice.other_transaction_id = data[:transaction_id]
          return_invoice.other_note = data[:transaction_note]
        end
      end
      return_invoice.department_name = inventory_invoice.department_name
      return_invoice.department_id = inventory_invoice.department_id
      return_invoice.recipient = inventory_invoice.recipient
      return_invoice.recipient_mobile = inventory_invoice.recipient_mobile
      return_invoice.patient_identifier = inventory_invoice.patient_identifier
      return_invoice.patient_id = inventory_invoice.patient_id
      return_invoice.user_id = inventory_invoice.user_id
      return_invoice.store_name = store.name
      return_invoice.store_id = inventory_invoice.store_id
      return_invoice.facility_id = inventory_invoice.facility_id
      return_invoice.organisation_id = inventory_invoice.organisation_id
      return_invoice.return_from_cancellation = true
      return_invoice.currency_id = inventory_invoice.currency_id
      return_invoice.currency_symbol = inventory_invoice.currency_symbol
      return_invoice.specialty_id = inventory_invoice.specialty_id
      return_invoice.return_time = Time.now
      return_invoice.invoice_received_amount = inventory_invoice.payment_received
      return_invoice.invoice_total_amount = inventory_invoice.net_amount
      # Added by Dhara on 2021-07-27
      return_invoice.is_canceled = inventory_invoice.is_canceled
      # TO DO: Add cancel_date, canceled_by_id, canceled_by in return_invoice model
      return_invoice.tax_breakup = inventory_invoice.tax_breakup
      return_invoice.taxable_amount = inventory_invoice.non_taxable_amount
      discount_percentage = inventory_invoice.total_of_all_discount / inventory_invoice.total
      return_invoice.srn_id = inventory_invoice.srn_id
      return_invoice.save!

      region_master_id = Facility.find_by(id: inventory_invoice.try(:facility_id)).try(:region_master_id)
      return_bill_number = SequenceManagers::GenerateSequenceService.call('return', return_invoice.id.to_s, {
        organisation_id: inventory_invoice.organisation_id.to_s, facility_id: inventory_invoice.facility_id.to_s,
        region_id: region_master_id.to_s,
        department_id: inventory_invoice.department_id.to_s
      })
      return_invoice.update(return_bill_number: return_bill_number)
      return unless inventory_invoice_items.present?

      inventory_invoice_items.each do |invoice_item|
        return_items = return_invoice.items
        item = return_items.new
        item.item_code = invoice_item.item_code
        item.variant_code = invoice_item.variant_code
        item.category = invoice_item.category
        item.description = invoice_item.description
        item.item_reference_id = invoice_item.item_reference_id
        item.variant_reference_id = invoice_item.variant_reference_id
        item.tax_rate = invoice_item.tax_rate
        item.tax_name = invoice_item.tax_name
        item.tax_group_id = invoice_item.tax_group_id
        item.tax_group = invoice_item.tax_group
        item.total_tax_amount = invoice_item.tax_group.sum { |tax| tax[:amount].to_f }
        item.tax_inclusive = invoice_item.tax_inclusive
        item.batch_no = invoice_item.batch_no
        item.model_no = invoice_item.model_no
        item.self_batched = invoice_item.self_batched
        item.total_cost = invoice_item.total_list_price.to_f
        item.total_list_price = invoice_item.total_list_price.to_f

        list_price = invoice_item.total_list_price.to_f / invoice_item.quantity

        item.list_price = list_price
        item.search = invoice_item.search
        item.variant_identifier = invoice_item.variant_identifier
        item.custom_field_tags = invoice_item.custom_field_tags
        item.custom_field_data = invoice_item.custom_field_data

        unit_non_taxable_amount = invoice_item.unit_non_taxable_amount - (discount_percentage * invoice_item.unit_non_taxable_amount)
        item.unit_non_taxable_amount = unit_non_taxable_amount

        item.discount_amount = invoice_item.total_list_price.to_f * discount_percentage
        item.discount_display_amount = item.discount_amount

        item.unit_taxable_amount = invoice_item.unit_taxable_amount
        item.expiry = invoice_item.expiry
        item.expiry_present = invoice_item.expiry_present
        item.stock = invoice_item.quantity
        item.is_deleted = invoice_item.is_deleted
        item.empty = invoice_item.empty
        item.item_id = invoice_item.item_id
        item.is_verified = true
        item.store_id = invoice_item.store_id
        item.facility_id = invoice_item.facility_id
        item.organisation_id = invoice_item.organisation_id
        item.lot_id = invoice_item.lot_id
        item.variant_id = invoice_item.variant_id
        item.srn_required = invoice_item.srn_required
        item.srn_pending = invoice_item.srn_pending
        item.lot_unit_ids = invoice_item.lot_unit_ids

        item.save!
      end
      return_invoice
    end
  end
end
