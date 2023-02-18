class Invoice::UpdateOrderStateService
  class << self
    def call(order_id)
      inventory_order = Invoice::InventoryOrder.find_by(id: order_id)
      if inventory_order.net_amount.to_f > 0 && inventory_order.total_discount.to_f > 0
        inventory_order.is_paid_discounted = true
      elsif inventory_order.net_amount.to_f == 0  && inventory_order.total_discount.to_f > 0
        inventory_order.is_free_discounted = true
      elsif inventory_order.net_amount.to_f > 0 && inventory_order.total_discount.to_f == 0
        inventory_order.is_paid = true
      else
        inventory_order.is_free = true
      end

      inventory_order.migration = true
      inventory_order.is_migrated = true
      inventory_order.save
    rescue StandardError => e
      Rails.logger.error(" === Error in UpdateOrderStateService : #{e.inspect}")
    end
  end
end
