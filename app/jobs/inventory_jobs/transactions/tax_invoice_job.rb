class InventoryJobs::Transactions::TaxInvoiceJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    transaction_id = args[0]
    type = args[1]
    current_user_id = args[2]
    action_from = args[3]
    tax_invoice = Inventory::TaxInvoice.find_by(id: transaction_id)
    transfer_ids = tax_invoice.transfer_ids
    transfer_ids.each do |transfer_id|
      transfer = Inventory::Transaction::Transfer.find_by(id: transfer_id)
      if action_from == 'create'
        unless transfer.is_tax_invoice_created || transfer.is_delivery_challan_created
          if type == 'delivery_challan'
            transfer.update!(is_delivery_challan_created: true, delivery_challan_created_by: current_user_id,
                             delivery_challan_created_on: Time.current)
          else
            transfer.update!(is_tax_invoice_created: true, tax_invoice_created_by: current_user_id,
                             tax_invoice_created_on: Time.current)
          end
        end
      elsif action_from == 'cancel'
        # unless transfer.is_tax_invoice_cancelled || transfer.is_delivery_challan_cancelled
          if type == 'delivery_challan'
            transfer.update!(is_delivery_challan_cancelled: true, delivery_challan_cancelled_by: current_user_id,
                             delivery_challan_cancelled_on: Time.current)
            transfer.update!(is_delivery_challan_created: false, delivery_challan_created_by: nil,
                             delivery_challan_created_on: Time.current)
          else
            transfer.update!(is_tax_invoice_cancelled: true, tax_invoice_cancelled_by: current_user_id,
                             tax_invoice_cancelled_on: Time.current)
            transfer.update!(is_tax_invoice_created: false, tax_invoice_created_by: nil,
                             tax_invoice_created_on: nil)
          end
        # end
      elsif action_from == 'approve'
        unless transfer.is_tax_invoice_approved || transfer.is_delivery_challan_approved
          if type == 'delivery_challan'
            transfer.update!(is_delivery_challan_approved: true, delivery_challan_approved_by: current_user_id,
                             delivery_challan_approved_on: Time.current)
          else
            transfer.update!(is_tax_invoice_approved: true, tax_invoice_approved_by: current_user_id,
                             tax_invoice_approved_on: Time.current)
          end
        end
      end
    end
  end
end
