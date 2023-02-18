module InventoryHelper
  def self.increment_and_create_return_purchase_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:purchase_return_transaction_counter) + 1
    organisation.update(purchase_return_transaction_counter: incremented)

    "#{organisation_prefix}-GRDN-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_purchase_transaction_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:purchase_transaction_counter) + 1
    organisation.update(purchase_transaction_counter: incremented)

    "#{organisation_prefix}-GRN-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_stock_opening_display_id(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:opening_stock_counter) + 1
    organisation.update(opening_stock_counter: incremented)

    "#{organisation_prefix}-OP-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_direct_stock_display_id(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:direct_stock_counter) + 1
    organisation.update(direct_stock_counter: incremented)

    "#{organisation_prefix}-DS-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  # def self.increment_and_create_purchase_display_number(store_id, current_facility_id)
  #   organisation_prefix = Facility.find_by(id: current_facility_id).organisation.identifier_prefix
  #   purchase_order = Inventory::Order::Purchase.where(store_id: store_id).order_by(created_at: 'desc').first
  #   incremented = if purchase_order
  #                   if purchase_order.purchase_display_id
  #                     purchase_order.purchase_display_id.split('-').last.to_i + 1
  #                   else
  #                     10000
  #                   end
  #                 else
  #                   10000
  #                 end

  #   "#{organisation_prefix}-#{Date.current.strftime('%d%m%y')}-#{incremented}"
  # end

  def self.increment_and_create_transfer_display_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:transfer_transaction_counter) + 1
    organisation.update(transfer_transaction_counter: incremented)

    "#{organisation_prefix}-TRA-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_issue_display_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:issue_transaction_counter) + 1
    organisation.update(issue_transaction_counter: incremented)

    "#{organisation_prefix}-ISS-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_receive_display_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:receive_transaction_counter) + 1
    organisation.update(receive_transaction_counter: incremented)

    "#{organisation_prefix}-REC-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_tray_display_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:tray_transaction_counter) + 1
    organisation.update(tray_transaction_counter: incremented)

    "#{organisation_prefix}-TR-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_store_consumption_transaction_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:store_consumption_transaction_counter) + 1
    organisation.update(store_consumption_transaction_counter: incremented)

    "#{organisation_prefix}-SC-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_adjustment_transaction_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:stock_adjustment_counter) + 1
    organisation.update(stock_adjustment_counter: incremented)

    "#{organisation_prefix}-ADJ-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_requisition_display_id(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:requisition_order_counter) + 1
    organisation.update(requisition_order_counter: incremented)

    "#{organisation_prefix}-REQ-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_requisition_received_display_id(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:requisition_received_order_counter) + 1
    organisation.update(requisition_received_order_counter: incremented)

    "#{organisation_prefix}-REQ-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_indent_display_id(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:indent_order_counter) + 1
    organisation.update(indent_order_counter: incremented)

    "#{organisation_prefix}-INDT-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_srn_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:srn_counter) + 1
    organisation.update(srn_counter: incremented)
    "#{organisation_prefix}-SRN-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_purchase_bill_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:purchase_bill_counter) + 1
    organisation.update(purchase_bill_counter: incremented)

    "#{organisation_prefix}-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_tax_invoice_display_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:tax_invoice_counter) + 1
    organisation.update(tax_invoice_counter: incremented)

    "#{organisation_prefix}-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end

  def self.increment_and_create_challan_display_number(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    organisation_prefix = organisation.identifier_prefix
    incremented = organisation.try(:delivery_challan_counter) + 1
    organisation.update(delivery_challan_counter: incremented)

    "#{organisation_prefix}-#{Time.current.strftime('%d%m%y')}-#{incremented}"
  end
end
