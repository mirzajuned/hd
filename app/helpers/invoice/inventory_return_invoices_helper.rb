module Invoice::InventoryReturnInvoicesHelper
  def self.increment_and_create_return_bill_number(store_id, current_facility_id)
    organisation_prefix = Facility.find_by(id: current_facility_id).organisation.identifier_prefix
    return_store_invoice = Inventory::Transaction::Return.where(store_id: store_id).order_by(created_at: 'desc').first
    incremented = if return_store_invoice
                    if return_store_invoice.return_bill_number
                      return_store_invoice.return_bill_number.split('-').last.to_i + 1
                    else
                      10000
                    end
                  else
                    10000
                  end

    "#{organisation_prefix}-#{Date.current.strftime('%d%m%y')}-#{incremented}"
  end
end
