class Inventory::Vendor::VendorPurchaseRateService
  class << self
    def call(transaction, variant, transaction_item)
      vendor_purchase_rate = Inventory::VendorPurchaseRateHistory.new
      purchase_order = Inventory::Order::Purchase.find_by(id: transaction.purchase_order_ids[0])
      return unless transaction.present? && variant.present?

      vendor_purchase_rate.variant_id = variant.id
      vendor_purchase_rate.variant_name = variant.description
      vendor_purchase_rate.variant_code = variant.variant_code
      vendor_purchase_rate.variant_reference_id = variant.reference_id
      vendor_purchase_rate.variant_identifier = variant.variant_identifier
      vendor_purchase_rate.purchase_rate = transaction_item.unit_cost_without_tax
      vendor_purchase_rate.paid_quantity = transaction_item.paid_stock
      vendor_purchase_rate.free_quantity = transaction_item.stock_free_unit
      vendor_purchase_rate.grn_number = transaction.purchase_display_id
      vendor_purchase_rate.grn_date_time = transaction.transaction_time
      if purchase_order.present?
        vendor_purchase_rate.po_number = purchase_order.purchase_display_id
        vendor_purchase_rate.po_date_time = purchase_order.order_date_time
      end
      vendor_purchase_rate.category = variant.category
      vendor_purchase_rate.category_id = variant.category_id
      vendor_purchase_rate.sub_category_id = variant.sub_category_id
      vendor_purchase_rate.is_active = true
      vendor_purchase_rate.transaction_item_id = transaction_item.id
      vendor_purchase_rate.vendor_id = transaction.vendor_id
      vendor_purchase_rate.vendor_name = transaction.vendor_name
      vendor_purchase_rate.store_id = transaction.store_id
      vendor_purchase_rate.user_id = transaction.user_id
      vendor_purchase_rate.facility_id = transaction.facility_id
      vendor_purchase_rate.organisation_id = transaction.organisation_id
      vendor_purchase_rate.save!
    end
  end
end
