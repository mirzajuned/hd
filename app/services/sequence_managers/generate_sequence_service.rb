class SequenceManagers::GenerateSequenceService
  class << self
    def call(module_name, module_id, extra_info={})
      organisation_id = extra_info[:organisation_id]
      facility_id = extra_info[:facility_id]
      module_obj =  if module_name == 'return' 
                      Inventory::Transaction::Return.find_by(id: module_id)
                    elsif module_name == 'sales_order'
                      Invoice::InventoryOrder.find_by(id: module_id)
                    elsif module_name == 'indent_order'
                      Inventory::Order::Indent.find_by(id: module_id)
                    elsif module_name == 'son_transaction'
                      Inventory::Transaction::StockOpening.find_by(id: module_id)
                    elsif module_name == 'purchase_return_transaction'
                      Inventory::Transaction::VendorReturn.find_by(id: module_id)
                    elsif module_name == 'purchase_transaction'
                      Inventory::Transaction::Purchase.find_by(id: module_id)
                    elsif module_name == 'srn'
                      Inventory::Transaction::StockReceiveNote.find_by(id: module_id)
                    elsif module_name == 'stock_adjustment'
                      Inventory::Transaction::Adjustment.find_by(id: module_id)
                    else
                      module_name.camelize.constantize.find_by(id: module_id)
                    end
      sub_module_obj = (module_name == 'patient') ? module_obj.patient_identifiers.last : nil
      module_name = if module_name == 'return'
                      'refund_payment'
                    else
                      module_name
                    end
      department_id = extra_info[:department_id]
      store_id = extra_info[:store_id]

      # Org Level
      max_counter = SequenceManager.where(organisation_id: organisation_id, module_name: module_name, counter_level: 'organisation', is_active: true).pluck(:organisation_counter).max

      org_sequences = SequenceManager.where(organisation_id: organisation_id, module_name: module_name, counter_level: 'organisation', is_active: true)
      org_original_counter = org_sequences.last.original_counter.to_i
      org_current_counter = max_counter.to_i
      org_new_counter = SequenceManagers::GenerateSequenceService.check_counter(org_original_counter, org_current_counter)
      org_sequences.update_all(organisation_counter: org_new_counter, current_counter: org_new_counter)
      # org_sequence.save!

      # other sequences
      sequences = SequenceManager.where(organisation_id: organisation_id, module_name: module_name, department_id: department_id, is_active: true)

      entity_group_id = extra_info[:entity_group_id]
      region_id = extra_info[:region_id]
      final_sequence = module_sequence = ''
      sequences.each do |sequence|
        original_counter = sequence.original_counter.to_i
        if sequence.counter_level == 'organisation'
        #   current_counter = sequence.organisation_counter.to_i
        #   new_counter = SequenceManagers::GenerateSequenceService.check_counter(original_counter, current_counter)
        #   sequence.organisation_counter = new_counter
        #   sequence.current_counter = new_counter
        elsif sequence.counter_level == 'facility' && sequence.facility_id.to_s == facility_id
          current_counter = sequence.facility_counter.to_i
          new_counter = SequenceManagers::GenerateSequenceService.check_counter(original_counter, current_counter)
          sequence.facility_counter = new_counter
          sequence.current_counter = new_counter
        elsif sequence.counter_level == 'region' && sequence.region_id.to_s == region_id
          current_counter = sequence.region_counter.to_i
          new_counter = SequenceManagers::GenerateSequenceService.check_counter(original_counter, current_counter)
          sequence.region_counter = new_counter
          sequence.current_counter = new_counter
        elsif sequence.counter_level == 'entity_group'
          if entity_group_id.present? && sequence.entity_group_id.to_s == entity_group_id
            current_counter = sequence.entity_group_counter.to_i
            new_counter = SequenceManagers::GenerateSequenceService.check_counter(original_counter, current_counter)
            sequence.entity_group_counter = new_counter
            sequence.current_counter = new_counter
          elsif !entity_group_id.present? && sequence.is_primary
            sequences.update_all(is_primary: false)
            org_sequence = sequences.find_by(counter_level: 'organisation')
            org_sequence.update(is_primary: true)
            sequence = org_sequence
          end
        elsif sequence.counter_level == 'store' && sequence.store_id.to_s == store_id
          current_counter = sequence.store_counter.to_i
          new_counter = SequenceManagers::GenerateSequenceService.check_counter(original_counter, current_counter)
          sequence.current_counter = new_counter
          sequence.store_counter = new_counter
        end
        sequence.save!
        final_sequence = SequenceManager::GenerateSequenceHelper.sequence_generate(sequence.id.to_s, '', extra_info)
        if sequence.is_primary.present? && ((sequence.counter_level == 'organisation') || (sequence.counter_level == 'facility' && sequence.facility_id.to_s == facility_id) || (sequence.counter_level == 'entity_group' && sequence.entity_group_id.to_s == entity_group_id) || (sequence.counter_level == 'region' && sequence.region_id.to_s == region_id) || (sequence.counter_level == 'store' && sequence.store_id.to_s == store_id))
          module_sequence = final_sequence 
        end
        if sub_module_obj.present?
          sub_module_obj.sequences.create(sequence_id: sequence.id, display_format: final_sequence, is_primary: sequence.is_primary, is_active: sequence.is_active, date: Date.current, time: Time.current)
        else
          module_obj.sequences.create(sequence_id: sequence.id, display_format: final_sequence, is_primary: sequence.is_primary, is_active: sequence.is_active, date: Date.current, time: Time.current)
        end
      end

      # EOF sequences each loop
      module_sequence
    end
    # EOF call

    def check_counter(original_counter, current_counter)
      if current_counter.to_i == 0
        current_counter = original_counter.to_i
      elsif original_counter.to_i > current_counter.to_i
        current_counter = original_counter.to_i
      else
        current_counter = current_counter.to_i + 1
      end
      current_counter.to_i
    end
    # EOF check_counter
  end
end