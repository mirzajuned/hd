class InventoryJobs::Orders::UpdateRequisitionVariantsJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    requisition_id = args[0]
    action = args[1]

    requisition_order = Inventory::Order::Requisition.find_by(id: requisition_id)
    if requisition_order.present? && requisition_order.items.present?
      requisition_order.items.each do |item|
        variant = Inventory::Item::Variant.find_by(id: item.variant_id)
        if action == 'disable'
          variant.update(peding_requisition_validation: false)
        else
          variant.update(peding_requisition_validation: true)
        end
      end
    end
  end
end
