module Invoice::Inventories::Department::PharmacyHelper
  def self.increment_and_create_bill_number(facility_id)
    organisation_prefix = Facility.find(facility_id).organisation.identifier_prefix
    pharmacy_invoice = Invoice::Inventories::Department::PharmacyInvoice.where(facility_id: facility_id).order_by(:created_at => 'desc').first
    # "HG-060516-10000"
    if pharmacy_invoice
      if pharmacy_invoice.bill_number
        incremented = pharmacy_invoice.bill_number.split("-").last.to_i + 1
      else
        incremented = 10000
      end
    else
      incremented = 10000
    end

    "#{organisation_prefix}-#{Date.current.strftime('%d%m%y')}-#{incremented}"
  end
end
