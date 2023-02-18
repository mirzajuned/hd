class InventoryJobs::Orders::CreateIndentJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    requisition_received_id = args[0]
    order_id = args[1]
    user_id = args[2]
    user = User.find_by(id: user_id)
    requisition_order = Inventory::Order::RequisitionReceived.find_by(id: requisition_received_id)
    indent = Inventory::Order::Indent.new
    store = Inventory::Store.find_by(id: requisition_order.store_id)
    indent.remarks = 'Created from Optical Order'
    indent.vendor_id = requisition_order.vendor_id
    indent.indent_type = 'Urgent'
    indent.indent_date = Date.current
    indent.indent_date_time = Time.current
    indent.created_by = user.fullname
    indent.created_by_id = user.id
    indent.user_id = user.id
    indent.store_id = requisition_order.store_id
    indent.facility_id = requisition_order.facility_id
    indent.organisation_id = requisition_order.organisation_id
    indent_display_id = InventoryHelper.increment_and_create_indent_display_id(requisition_order.organisation_id.to_s)
    indent.indent_display_id = indent_display_id
    indent.department_id = store&.department_id
    indent.department_name = store&.department_name
    indent.status = 'Open'
    indent.optical_order_id = order_id
    indent.requisition_order_id = requisition_order.requisition_order_id

    requisition_order.items.each do |item|
      indent_item_params = item.attributes.except(:_id)
      indent_item_params[:remaining_stock] = item.stock
      indent.items.build(indent_item_params)
    end
    Inventory::Orders::CreatePurchaseOrderService.call(indent.id, user_id) if indent.save!
  end
end
