module Inventory::PurchaseOrderHelper
  def po_store_format(store)
    store_name = store&.name
    facility_name = store&.facility_name&.titleize
    address = []
    address << store&.address << store&.city << store&.commune << store&.district << store&.state << store&.pincode
    address = address.reject(&:blank?)&.join(', ')

    store ? "#{store_name} #{"- #{address}"}" : '-'
  end

  def self.shipping_address(store)
    facility_name = store&.facility_name&.titleize
    address = []
    address << store&.address << store&.city << store&.commune << store&.district << store&.state << store&.pincode
    address = address.reject(&:blank?)&.join(', ')

    store ? "#{"#{address}"}" : '-'
  end

  def self.billing_address(store)
    facility_name = store&.facility_name&.titleize
    address = []
    address << store&.billing_address << store&.billing_city << store&.billing_commune << store&.billing_district << store&.billing_state << store&.billing_pincode
    address = address.reject(&:blank?)&.join(', ')

    store ? "#{"#{address}"}" : '-'
  end

  def po_vendor_format(vendor)
    address = []
    address << vendor&.address << vendor&.city << vendor&.district << vendor&.state << vendor&.pincode
    address = address.reject(&:blank?)&.join(', ')
    vendor_name = vendor&.name

    vendor_name ? "#{vendor_name} #{"- #{address}"}" : '-'
  end

  def po_vendor_location_format(vendor_location)
    address = []
    address << vendor_location&.address << vendor_location&.city << vendor_location&.district << vendor_location&.state << vendor_location&.pincode
    address = address.reject(&:blank?)&.join(', ')
    vendor_name = vendor_location&.name
    vendor_name ? "#{vendor_name} #{"- #{address}"}" : '-'
  end

  def self.po_vendor_location_address(vendor_location)
    address = []
    address << vendor_location&.address << vendor_location&.city << vendor_location&.district << vendor_location&.state << vendor_location&.pincode
    address = address.reject(&:blank?)&.join(', ')
    vendor_name = vendor_location&.name
    vendor_name ? "#{vendor_name} #{"- #{address}"}" : '-'
  end
end
