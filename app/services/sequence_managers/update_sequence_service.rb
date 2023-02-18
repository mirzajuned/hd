class SequenceManagers::UpdateSequenceService
  class << self
    def call(type, _id)
      # facility
      if type == 'facility'
        facility = Facility.find_by(id: _id)
        organisation_id = facility.organisation_id
        SequenceManagers::UpdateSequenceService.upsert_sequences(organisation_id, 'facility', facility)
        region_id = facility.try(:region_master_id)
        region_master = RegionMaster.find_by(id: region_id) if region_id.present?
        SequenceManagers::UpdateSequenceService.upsert_sequences(organisation_id, 'region', region_master) if region_master.present?
      elsif type == 'region'
        region_master = RegionMaster.find_by(id: _id)
        organisation_id = region_master.organisation_id
        SequenceManagers::UpdateSequenceService.upsert_sequences(organisation_id, 'region', region_master)
      end
    end
    # EOF call

    def upsert_sequences(organisation_id, type, type_obj)
      type_obj_sequence_modules = SequenceManager.where(organisation_id: organisation_id, counter_level: type).pluck(:module_name).uniq
      type_obj_sequence_modules.each do |module_name|
        type_obj_sequences = SequenceManager.where(:"#{type}_id" => type_obj.id, organisation_id: organisation_id, module_name: module_name)
        if type_obj_sequences.count > 0
          type_obj_sequences.update_all(:"#{type}_name" => type_obj.try(:name), :"#{type}_abbreviation" => type_obj.try(:abbreviation))
        else
          sequence_departments = SequenceManager.where(organisation_id: organisation_id, counter_level: type, module_name: module_name).pluck(:department_id).uniq
          sequence_departments.each do |sequence_department|
            sequence_manager = SequenceManager.find_by(organisation_id: organisation_id, counter_level: type, module_name: module_name, department_id: sequence_department)
            type_obj_sequence = SequenceManager.find_or_create_by(:"#{type}_id" => type_obj.id, organisation_id: organisation_id, module_name: module_name, counter_level: sequence_manager.try(:counter_level), department_id: sequence_manager.try(:department_id))
            type_obj_sequence.original_counter = sequence_manager.try(:original_counter) || 1
            type_obj_sequence.counter_length = sequence_manager.try(:counter_length).to_i
            type_obj_sequence.display_name = sequence_manager.try(:display_name)

            type_obj_sequence.organisation_abbreviation = sequence_manager.try(:organisation_abbreviation)
            type_obj_sequence.department_name = sequence_manager.try(:department_name)
            type_obj_sequence.department_abbreviation = sequence_manager.try(:department_abbreviation)
            type_obj_sequence.department_order = sequence_manager.try(:department_order)
            
            type_obj_sequence["#{type}_name"] = type_obj.try(:name)
            type_obj_sequence["#{type}_abbreviation"] = type_obj.try(:abbreviation)

            type_obj_sequence.prefix_level = sequence_manager.try(:prefix_level)
            type_obj_sequence.module_prefix = sequence_manager.try(:module_prefix)
            type_obj_sequence.display_format = sequence_manager.try(:display_format)
            type_obj_sequence.has_date = sequence_manager.try(:has_date)
            type_obj_sequence.date_format = sequence_manager.try(:date_format)
            type_obj_sequence.reset_on_newyear = sequence_manager.try(:reset_on_newyear)
            type_obj_sequence.reset_month = sequence_manager.try(:reset_month).to_i
            type_obj_sequence.year_format = sequence_manager.try(:year_format)
            type_obj_sequence.is_primary = sequence_manager.try(:is_primary)
            type_obj_sequence.is_active = sequence_manager.try(:is_active)
            type_obj_sequence.save!
          end
        end
      end
    end
    # EOF upsert_sequences 
  end
end