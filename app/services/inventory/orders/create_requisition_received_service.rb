class Inventory::Orders::CreateRequisitionReceivedService
  class << self
    def call(requisition_order_id)
      requisition_order = Inventory::Order::Requisition.find_by(id: requisition_order_id)
      return unless requisition_order.items.present?

      requisition_received = Inventory::Order::RequisitionReceived.new
      requisition_received.requisition_order_date = Date.current
      requisition_received.requisition_order_time = Time.current
      requisition_received.status = 'Pending'
      requisition_received.requisition_received_display_id = InventoryHelper.increment_and_create_requisition_received_display_id(requisition_order.organisation_id)
      requisition_received.is_deleted = false
      requisition_received.is_active = true
      requisition_received.store_id = requisition_order.receive_store_id
      requisition_received.store_name = requisition_order.receive_store_name
      requisition_received.requisition_approved_date = requisition_order.approved_date_time
      requisition_received.requisition_approved_time = requisition_order.approved_date_time
      requisition_received.requisition_order_id = requisition_order_id
      requisition_received.requisition_order_created_by_id = requisition_order.entered_by_id
      requisition_received.requisition_order_created_by_name = requisition_order.entered_by
      requisition_received.requisition_order_store_name = requisition_order.store_name
      requisition_received.requisition_order_store_id = requisition_order.store_id
      requisition_received.requisition_order_department_name = requisition_order.department_name
      requisition_received.requisition_order_department_id = requisition_order.department_id
      requisition_received.requisition_order_approved_by_id = requisition_order.approved_by_id
      requisition_received.requisition_order_approved_by_name = requisition_order.approved_by
      requisition_received.user_id = requisition_order.user_id
      requisition_received.facility_id = requisition_order.facility_id
      requisition_received.organisation_id = requisition_order.organisation_id
      requisition_received.requisition_type = requisition_order.requisition_type
      requisition_received.created_from = requisition_order.created_from
      requisition_received.remarks = requisition_order.remarks
      requisition_received.requisition_created_at = requisition_order.requisition_date_time
      requisition_received.requisition_display_id = requisition_order.requisition_display_id
      requisition_received.vendor_id = requisition_order.vendor_id
      requisition_received.optical_order_id = requisition_order.optical_order_id

      requisition_order.items.each do |item|
        requisition_received_item_params = item.attributes.except(:_id, :store_id)
        requisition_received_item_params.merge!(
          remaining_stock: item.stock, store_id: requisition_order.receive_store_id, requisition_item_id: item.id
        )
        requisition_received.items.build(requisition_received_item_params)
        variant = Inventory::Item::Variant.find_by(id: item.variant_id)
        requested_quantity = variant&.requested_quantity.to_f + item&.stock.to_f
        variant.update!(requested_quantity: requested_quantity, requisition_validation: false, issue_requisition_validation: false,
                        peding_requisition_validation: false)
      end

      requisition_received.save!
      requisition_received.id
    end
  end
end
