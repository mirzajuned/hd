class SequenceManagerJobs::ManageJob < ActiveJob::Base
  queue_as :urgent

  def perform(sequence_manager_id, extra_info)
    sequence_manager = SequenceManager.find_by(id: sequence_manager_id)
    if sequence_manager.present?
      organisation_id = sequence_manager.organisation_id
      organisation_abbreviation = sequence_manager.try(:organisation_abbreviation)

      counter_level = sequence_manager.try(:counter_level)
      module_name = sequence_manager.try(:module_name)

      # update all the org level new counter for current module
      if(sequence_manager.counter_level == 'organisation' && sequence_manager.current_counter < sequence_manager.original_counter)
        org_sequences = SequenceManager.where(organisation_id: sequence_manager.organisation_id, counter_level: 'organisation', module_name: module_name)
        org_sequences.update_all(original_counter: sequence_manager.original_counter)
      end
      # EOF update all the org level new counter for current module

      # soft delete old changes
      SequenceManager.where(organisation_id: sequence_manager.try(:organisation_id), counter_level: extra_info['old_counter_level'], module_name: module_name, department_id: sequence_manager.try(:department_id)).update_all(is_deleted: true) if extra_info['old_counter_level'].present? && extra_info['old_counter_level'] != counter_level
      # EOF soft delete old changes

      # upsert seq for facility counter for the organisation
      if extra_info['facility_details'].present? && counter_level == 'facility'
        existing_facility_sequences = SequenceManager.where(organisation_id: sequence_manager.try(:organisation_id), counter_level: counter_level, module_name: module_name, department_id: sequence_manager.try(:department_id))
        if existing_facility_sequences.count == extra_info['facility_details'].count
          existing_facility_sequences.update_all(is_deleted: false)
        else
          extra_info['facility_details'].each do |key, val|
            f_sequence = SequenceManager.find_or_create_by(facility_id: BSON::ObjectId(key), organisation_id: organisation_id, counter_level: counter_level, module_name: module_name, department_id: sequence_manager.try(:department_id))
            f_sequence.original_counter = (val['original_counter'].to_i == 0) ? 1 : val['original_counter'].to_i
            
            f_sequence.counter_length = sequence_manager.try(:counter_length).to_i
            f_sequence.display_name = sequence_manager.try(:display_name)

            f_sequence.department_name = sequence_manager.try(:department_name)
            f_sequence.department_abbreviation = sequence_manager.try(:department_abbreviation)
            f_sequence.department_order = sequence_manager.try(:department_order)
            f_sequence.organisation_abbreviation = sequence_manager.try(:organisation_abbreviation)

            f_sequence.facility_name = val['name']
            f_sequence.facility_abbreviation = val['abbreviation']
            f_sequence.prefix_level = sequence_manager.try(:prefix_level)
            f_sequence.module_prefix = sequence_manager.try(:module_prefix)
            f_sequence.display_format = sequence_manager.try(:display_format)
            f_sequence.has_date = sequence_manager.try(:has_date)
            f_sequence.date_format = sequence_manager.try(:date_format)
            f_sequence.reset_on_newyear = sequence_manager.try(:reset_on_newyear)
            f_sequence.reset_month = sequence_manager.try(:reset_month).to_i
            f_sequence.year_format = sequence_manager.try(:year_format)
            f_sequence.is_primary = sequence_manager.try(:is_primary)
            f_sequence.is_active = sequence_manager.try(:is_active)
            f_sequence.is_deleted = false
            f_sequence.save!
          end
        end
      end
      # EOF create seq for facility counter for the organisation
      # upsert seq for region counter for the organisation
      if extra_info['region_details'].present? && counter_level == 'region'
        existing_region_sequences = SequenceManager.where(organisation_id: sequence_manager.try(:organisation_id), counter_level: counter_level, module_name: module_name, department_id: sequence_manager.try(:department_id))
        if existing_region_sequences.count == extra_info['region_details'].count
          existing_region_sequences.update_all(is_deleted: false)
        else
          extra_info['region_details'].each do |key, val|
            f_sequence = SequenceManager.find_or_create_by(region_id: key, organisation_id: organisation_id, counter_level: counter_level, module_name: module_name, department_id: sequence_manager.try(:department_id))
            f_sequence.original_counter = (val['original_counter'].to_i == 0) ? 1 : val['original_counter'].to_i
            f_sequence.counter_length = sequence_manager.try(:counter_length).to_i
            f_sequence.display_name = sequence_manager.try(:display_name)

            f_sequence.department_name = sequence_manager.try(:department_name)
            f_sequence.department_abbreviation = sequence_manager.try(:department_abbreviation)
            f_sequence.department_order = sequence_manager.try(:department_order)
            f_sequence.organisation_abbreviation = sequence_manager.try(:organisation_abbreviation)

            f_sequence.region_name = val['name']
            f_sequence.region_abbreviation = val['abbreviation']
            f_sequence.prefix_level = sequence_manager.try(:prefix_level)
            f_sequence.module_prefix = sequence_manager.try(:module_prefix)
            f_sequence.display_format = sequence_manager.try(:display_format)
            f_sequence.has_date = sequence_manager.try(:has_date)
            f_sequence.date_format = sequence_manager.try(:date_format)
            f_sequence.reset_on_newyear = sequence_manager.try(:reset_on_newyear)
            f_sequence.reset_month = sequence_manager.try(:reset_month).to_i
            f_sequence.year_format = sequence_manager.try(:year_format)
            f_sequence.is_primary = sequence_manager.try(:is_primary)
            f_sequence.is_active = sequence_manager.try(:is_active)
            f_sequence.is_deleted = false
            f_sequence.save!
          end
        end
      end
      # EOF upsert seq for region counter for the organisation

      # upsert seq for entity_group counter for the organisation
      if extra_info['entity_group_details'].present? && counter_level == 'entity_group'
        existing_entity_group_sequences = SequenceManager.where(organisation_id: sequence_manager.try(:organisation_id), counter_level: counter_level, module_name: module_name, department_id: sequence_manager.try(:department_id))
        if existing_entity_group_sequences.count == extra_info['entity_group_details'].count
          existing_entity_group_sequences.update_all(is_deleted: false)
        else
          extra_info['entity_group_details'].each do |key, val|
            f_sequence = SequenceManager.find_or_create_by(entity_group_id: key, organisation_id: organisation_id, counter_level: counter_level, module_name: module_name, department_id: sequence_manager.try(:department_id))
            f_sequence.original_counter = (val['original_counter'].to_i == 0) ? 1 : val['original_counter'].to_i
            f_sequence.counter_length = sequence_manager.try(:counter_length).to_i
            f_sequence.display_name = sequence_manager.try(:display_name)

            f_sequence.department_name = sequence_manager.try(:department_name)
            f_sequence.department_abbreviation = sequence_manager.try(:department_abbreviation)
            f_sequence.department_order = sequence_manager.try(:department_order)
            f_sequence.organisation_abbreviation = sequence_manager.try(:organisation_abbreviation)

            f_sequence.entity_group_name = val['name']
            f_sequence.entity_group_abbreviation = val['abbreviation']
            f_sequence.prefix_level = sequence_manager.try(:prefix_level)
            f_sequence.module_prefix = sequence_manager.try(:module_prefix)
            f_sequence.display_format = sequence_manager.try(:display_format)
            f_sequence.has_date = sequence_manager.try(:has_date)
            f_sequence.date_format = sequence_manager.try(:date_format)
            f_sequence.reset_on_newyear = sequence_manager.try(:reset_on_newyear)
            f_sequence.reset_month = sequence_manager.try(:reset_month).to_i
            f_sequence.year_format = sequence_manager.try(:year_format)
            f_sequence.is_primary = sequence_manager.try(:is_primary)
            f_sequence.is_active = sequence_manager.try(:is_active)
            f_sequence.is_deleted = false
            f_sequence.save!
          end
        end
      end
      # EOF upsert seq for entity_group counter for the organisation
      # puts '$'*20
    end
  end
  # EOF perform
end