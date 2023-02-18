class SequenceManagers::CreateSequenceDetailsService
  class << self
    def call(is_primary, counter_level, organisation_id, prefix_level, module_hash, module_name)
      @is_primary = is_primary
      @counter_level = counter_level
      @organisation_id = organisation_id
      @prefix_level = prefix_level
      @module_hash = module_hash
      @module_name = module_name
      @has_date = @module_hash[@module_name][:has_date] || false
      if @has_date == true
        @display_format = $display_date_format
      else
        @display_format = $display_format
      end
      @organisation = Organisation.find_by(id: @organisation_id)
      @organisation_abbreviation = @organisation.try(:identifier_prefix)
      sequence_module = @module_hash[@module_name][:organisation_module]
      @current_counter = @organisation.send("#{sequence_module}_counter").to_i
      @original_counter = @module_hash[@module_name][:original_counter]
      @department_ids = @module_hash[@module_name][:department_ids]
      @has_entity = @module_hash[@module_name][:has_entity] || false
      if @department_ids.present?
        @department_ids.each do |department_id|
          sequencemanager = SequenceManager.find_by(organisation_id: @organisation.id, department_id: department_id, counter_level: @counter_level, module_name: @module_name)
          SequenceManagers::CreateSequenceDetailsService.create_seq(department_id) unless sequencemanager.present?
        end
        # EOF department_ids each
      else
        sequencemanager = SequenceManager.find_by(organisation_id: @organisation.id, counter_level: counter_level, module_name: module_name)
        SequenceManagers::CreateSequenceDetailsService.create_seq unless sequencemanager.present?
      end
    end
    # EOF call

    def create_seq(department_id=nil)
      if department_id.present?
        department = Department.find_by(id: department_id)
        department_name = department.try(:name)
        department_abbreviation = department.try(:display_name)
        department_order = department.try(:order)
        sequence_manager = SequenceManager.find_or_create_by(organisation_id: @organisation.id, department_id: department_id, counter_level: @counter_level, module_name: @module_name)
        sequence_manager.department_name = department_name
        sequence_manager.department_abbreviation = department_abbreviation
        sequence_manager.department_order = department_order
        department_inital = if department_id.to_s == '550368792'
                              'HUB'
                            else
                              department_abbreviation.gsub(/\s+/, "")[0..2].upcase
                            end
      else
        sequence_manager = SequenceManager.find_or_create_by(organisation_id: @organisation.id, counter_level: @counter_level, module_name: @module_name)
      end
      # sequence_manager.module_prefix = if department_inital.present?
      #                                     "#{@module_hash[@module_name][:abbreviation]}-#{department_inital}"
      #                                   else
      #                                     @module_hash[@module_name][:abbreviation]
      #                                   end
      sequence_manager.module_prefix = @module_hash[@module_name][:abbreviation]
      sequence_manager.prefix_level = @prefix_level
      sequence_manager.original_counter = @original_counter
      sequence_manager.current_counter = @current_counter
      sequence_manager.counter_length = @current_counter.to_s.length
      sequence_manager.display_name = @module_hash[@module_name][:display_name]
      sequence_manager.organisation_abbreviation = @organisation_abbreviation
      sequence_manager.organisation_counter = @current_counter
      sequence_manager.display_format = @display_format
      sequence_manager.date_format = '%d%m%y' if @has_date == true
      sequence_manager.is_primary = true
      sequence_manager.has_entity = @has_entity
      sequence_manager.save!
    end
    # EOF create_seq
  end
end