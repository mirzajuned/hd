json.sEcho params[:sEcho]
json.iTotalRecords @sequence_managers.count
json.iTotalDisplayRecords @sequence_managers.count
json.set! "aaData" do
  count = 0
  json.array!(@sequence_managers) do |module_name, seq_manager|
    s_managers = seq_manager.group_by { |sm| sm[:display_name] }
    s_managers.each do |item_name, s_manager|
      department_seq = s_manager.group_by{ |sm| sm[:department_id]}
      department_seq.each do |department_id, sd_manager|
        department_display_name = if (department_id.present?)
                                    sd_manager.first.department_abbreviation 
                                  else
                                    '-'
                                  end
        sd_manager.each_with_index do |sequence_manager, i|
          display_seq = ''
          if sequence_manager.prefix_level == 'region'
            display_seq = SequenceManager::GenerateSequenceHelper.index_sequences(sequence_manager.id, {organisation_id: current_organisation['_id'].to_s, facility_id: current_facility['_id'].to_s, region_id: current_facility['region_master_id'].to_s, department_id: department_id})
          elsif sequence_manager.prefix_level == 'entity_group'
            EntityGroup.where(organisation_id: current_organisation['_id'].to_s).pluck(:id).each do |entity_group_id|
              display_seq += SequenceManager::GenerateSequenceHelper.index_sequences(sequence_manager.id, {organisation_id: current_organisation['_id'].to_s, facility_id: current_facility['_id'].to_s, entity_group_id: entity_group_id.to_s, department_id: department_id})
            end
          else
            display_seq = SequenceManager::GenerateSequenceHelper.index_sequences(sequence_manager.id, {organisation_id: current_organisation['_id'].to_s, facility_id: current_facility['_id'].to_s, department_id: department_id})
          end
          default_radio = "<input type='radio' name='is_primary_#{sequence_manager.id.to_s}' id='#{sequence_manager.id.to_s}' value='#{i}' class='default_radio_btn primary_sequence' data-toggle='modal' data-target='#confirmation-modal' checked='checked'>"
          seq_properties = "<div><b>Counter Level:</b> #{(sequence_manager.counter_level.present?) ? sequence_manager.counter_level.titleize : '-'}</div><div><b>Prefix Level:</b> #{sequence_manager.prefix_level.titleize}</div><div><b>Auto Reset:</b> #{sequence_manager.reset_on_newyear.to_s.titleize}</div>"
          if sequence_manager.is_primary
            seq_properties += "<div><span class='badge badge-blue'><b>Primary</b></span></div>"
          end
          actions = ''
          if sequence_manager.try(:is_primary) && count_sequences('module_name', sequence_manager.module_name, true, department_id) < 3
            actions += "<a data-remote='true' data-toggle='modal' data-target='#sequence-manager-modal' class='btn btn-primary btn-xs' title='Create Sequence' href='/sequence_managers/new?department_id=#{department_id}&id=#{sequence_manager.id}&module_name=#{sequence_manager.module_name}'><i class='fa fa-plus'> Add</i></a>&nbsp;&nbsp;"
          end
          if sequence_manager.is_active
            actions += "<a data-remote='true' data-toggle='modal' data-target='#sequence-manager-modal' class='btn btn-info btn-xs' title='Edit Sequence' href='/sequence_managers/#{sequence_manager.id}/edit'><i class='fa fa-pencil-square-o'> Edit</i></a>&nbsp;&nbsp;"
            is_disabled = (sequence_manager.is_primary) ? 'none' : 'visible'
            if sequence_manager.is_primary
              actions += "<div class='btn btn-danger btn-disable-sequence' style='display: inline;' data-toggle='modal' data-target='#confirmation-modal' disabled>Disable</div>"
            else
              actions += "<div class='btn btn-danger btn-disable-sequence' style='display: inline;' data-toggle='modal' data-target='#confirmation-modal'>Disable</div>"
            end
            actions += "<a class='btn btn-danger btn-toggle' style='display: none; pointer-events: visible' data-dismiss='modal' data-method='delete' data-remote='true' href='/sequence_managers/#{sequence_manager.id}/disable_toggle?activate=false'>Disable</a>"
          else
          end
          json.set! "4", display_seq
          json.set! "5", default_radio
          json.set! "6", seq_properties
          json.set! "7", actions
        end
        json.set! "3", department_display_name
      end
      json.set! "2", item_name
    end
    json.set! "0", count+=1
    json.set! "1", module_name.try(:titleize)
  end
end
