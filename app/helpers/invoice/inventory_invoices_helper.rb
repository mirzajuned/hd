module Invoice::InventoryInvoicesHelper
  def self.increment_and_create_bill_number(store_id, current_facility_id)
    organisation_prefix = Facility.find_by(id: current_facility_id).organisation.identifier_prefix
    store_invoice = Invoice::InventoryInvoice.where(store_id: store_id).order_by(created_at: 'desc').first
    # "HG-060516-10000"
    incremented = if store_invoice
                    if store_invoice.bill_number
                      store_invoice.bill_number.split('-').last.to_i + 1
                    else
                      10000
                                  end
                  else
                    10000
                  end

    "#{organisation_prefix}-#{Date.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_order_number(organisation_id, is_sales=false)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix

    if is_sales
      field = :sales_order_counter
      prefix = "SO"
    else
      field = :purchase_order_counter
      prefix = "PO"
    end
    incremented = organisation.send(field) + 1
    organisation[field] = incremented
    organisation.save
    "#{organisation_prefix}-#{prefix}-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def xlsx_headings(dpt_id, gst_inc)
    tax_types = current_facility.country_id == 'IN_108' ? ['SGST', 'CGST'] : ['VAT', 'Others']
    headings = if gst_inc == '0'
                 ['BILLED ON', 'Bill NUMBER', 'RECIPIENT', 'RECIPIENT MOBILE', 'PATIENT ID', 'MRN', 'GROSS AMOUNT', 'DISCOUNT', 'OFFER', 'TAXABLE AMOUNT',
                  'TAX COLLECTED', 'NET AMOUNT', 'COMMENTS', 'CURRENT STATUS']
               else
                 ['BILLED ON', 'TAX BREKUPS', 'Bill NUMBER', 'RECIPIENT', 'RECIPIENT MOBILE', 'PATIENT ID', 'MRN', 'GROSS AMOUNT', 'DISCOUNT', 'OFFER',
                  'NET AMOUNT', 'TAXABLE VALUE', tax_types[0] + ' RATE %', tax_types[0] + ' AMOUNT',
                  tax_types[1] + ' RATE %', tax_types[1] + ' AMOUNT', 'TOTAL TAX AMOUNT', 'COMMENTS', 'CURRENT STATUS']
      end
    if dpt_id == '50121007'
      headings + ['STATE', 'DELIVERY DATE', 'FITTING REQUIRED', 'FITTER NAME']
    else
      headings
    end
  end
end
