class Inventory::Orders::CreateAutoRequisitionService
  class << self
    def call(store_id, requisition_store_id, is_auto_approval)
      inventory_store = Inventory::Store.find_by(id: store_id)
      # user = User.find_by(id: inventory_store.user_id)
      requisition_store = Inventory::Store.find_by(id: requisition_store_id)
      if inventory_store.requisition && requisition_store.requisition_fulfillment
        store_category_ids = inventory_store.category_ids
        requested_category_ids = requisition_store.category_ids
        category_ids = store_category_ids & requested_category_ids
        options = { store_id: store_id, stockable: true, :category_id.in => category_ids }
        variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc')

        requisition = Inventory::Order::Requisition.new
        requisition_display_id = InventoryHelper.increment_and_create_requisition_display_id(inventory_store.organisation_id)
        requisition.requisition_display_id = requisition_display_id
        requisition.remarks = 'Auto Requisition'
        requisition.receive_store_id = requisition_store.id
        requisition.receive_store_name = requisition_store.name
        requisition.requisition_type = 'system-generated'
        requisition.requisition_date = Date.current.strftime('%d/%m/%Y')
        requisition.requisition_date_time = Time.current
        requisition.requisition_time = Time.current.strftime('%I:%M %p')
        # requisition.entered_by_id = user&.id
        # requisition.entered_by = user.fullname
        requisition.store_id = inventory_store.id
        requisition.store_name = inventory_store.name
        requisition.facility_id = inventory_store.facility_id
        requisition.organisation_id = inventory_store.organisation_id
        requisition.requisition_creation_time = Time.current
        requisition.department_name = inventory_store.department_name
        requisition.department_id = inventory_store.department_id
        requisition.is_disabled = false
        requisition.is_active = true
        requisition.status = 'open'
        requisition.receive_status = 'Pending'
        requisition.created_from = 'Auto Requisition'
        variants.each do |variant|
          item = Inventory::Item.find_by(id: variant.item_id)
          rol_rule = Inventory::RolRule.find_by(store_id: variant.store_id, variant_reference_id: variant.reference_id,
                                                organisation_id: variant.organisation_id.to_s)
          pending_tranfered_quantity = variant.pending_tranfered_quantity || 0
          requested_quantity = variant.requested_quantity || 0
          effective_qty = variant.stock + pending_tranfered_quantity + requested_quantity
          next unless rol_rule.present? && rol_rule.rol_value > effective_qty

          max_value = rol_rule.try(:max_value) - effective_qty if rol_rule.try(:max_value).present?
          sub_units = item.item_units.to_i
          item_max_value = (max_value / sub_units) * sub_units
          requisition_item = requisition.items.build
          requisition_item.item_code = variant.item_code
          requisition_item.variant_code = variant.variant_code
          requisition_item.item_id = variant.item_id
          requisition_item.variant_id = variant.id
          requisition_item.category = variant.category_name
          requisition_item.barcode = variant.barcode
          requisition_item.barcode_present = variant.barcode_present
          requisition_item.variant_reference_id = variant.reference_id
          requisition_item.item_reference_id = item.reference_id
          requisition_item.variant_reference_id = variant.reference_id
          requisition_item.facility_id = variant.facility_id
          requisition_item.store_id = variant.store_id
          requisition_item.organisation_id = variant.organisation_id
          requisition_item.search = variant.search
          requisition_item.variant_identifier = variant.variant_identifier
          requisition_item.model_no = variant.model_no
          requisition_item.requested_quantity = item_max_value
          requisition_item.description = variant.description
          requisition_item.stock = item_max_value
        end
        requisition.save!
        if is_auto_approval
          requisition.update!(approved_date_time: Time.current, status: 'approved')
          Inventory::Orders::CreateRequisitionReceivedService.call(requisition.id)
        end
      end
    end
  end
end
