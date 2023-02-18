class InventoryJobs::Orders::RequisitionJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    requisition_id = args[0]

    requisition_order = Inventory::Order::Requisition.find_by(id: requisition_id)
    if requisition_order.present? && requisition_order.items.present?
      Inventory::Orders::CreateRequisitionReceivedService.call(requisition_id)
    end
  end
end
