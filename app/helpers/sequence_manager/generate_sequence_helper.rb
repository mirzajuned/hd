module SequenceManager::GenerateSequenceHelper
  def self.index_sequences(sequence_manager_id, extra_info)
    return SequenceManager::GenerateSequenceHelper.sequence_generate(sequence_manager_id, '', extra_info)
  end
  # EOF self.generate_sequence

  def self.preview_sequence(sequence_manager_id, new_sequence, extra_info = {})
    return SequenceManager::GenerateSequenceHelper.sequence_generate(sequence_manager_id, new_sequence, extra_info)
  end
  # EOF preview_sequence

  def self.sequence_generate(sequence_manager_id, sequence_str = '', extra_info = {})
    sequence_logger = Logger.new("#{Rails.root}/log/sequence_logger.log")
    sequence_manager = SequenceManager.find_by(id: sequence_manager_id)
    sequence_format = department_id = region = entity_group = prefix = ''
    date_format = year_format = reset_month = ''
    sequence_str = sequence_manager.display_format unless sequence_str.present?
    separators = Global.sequence_manager.separator
    counter_length = sequence_manager.try(:counter_length) || 6
    display_formats = sequence_str.split(',')
    if extra_info.present?
      organisation_id = extra_info[:organisation_id]
      if organisation_id.present?
        organisation = Organisation.find_by(id: organisation_id)
      end
      facility_id = extra_info[:facility_id]
      if facility_id.present?
        facility = Facility.find_by(id: facility_id)
      end
      entity_group_id = extra_info[:entity_group_id] || organisation.try(:entity_groups).try(:last).try(:id).to_s
      if entity_group_id.present?
        entity_group = EntityGroup.find_by(id: entity_group_id)
      end
      department_id = extra_info[:department_id] || nil
      region_id = extra_info[:region_id] || facility.try(:region_master_id).to_s
      if region_id.present?
        region = RegionMaster.find_by(id: region_id)
      end
      store_id = extra_info[:store_id]
      if store_id.present?
        store = Inventory::Store.find_by(id: store_id)
      end
      date_format = extra_info[:date_format] || sequence_manager.try(:date_format)
      year_format = extra_info[:year_format] || sequence_manager.try(:year_format)
      reset_month = (extra_info[:reset_month].to_i == 0) ? sequence_manager.try(:reset_month).to_i : extra_info[:reset_month].to_i
    end
    if sequence_manager.nil? && organisation.present?
      sequence_manager = SequenceManager.new
      sequence_manager.organisation_abbreviation = organisation.identifier_prefix
      sequence_manager.facility_name = facility.name
      sequence_manager.facility_abbreviation = facility.abbreviation
      sequence_manager.facility_counter = 200001
      sequence_manager.date_format = date_format
    end
    sequence_manager.facility_abbreviation = facility.try(:abbreviation)
    display_formats.try(:each) do |d_format|
      # binding.pry if sequence_manager.id.to_s == '627b953e2c6b84109810960b'
      if d_format.to_nil.to_s.in?(separators)
        sequence_format += d_format
      elsif d_format == 'has_date'
        sequence_format += Date.current.strftime(date_format)
      elsif d_format == 'year_format'
        if reset_month == 0 || reset_month == 1
          sequence_format += Date.current.strftime('%Y')
        elsif reset_month.present?
          current_month = Date.current.month
          current_year = Date.current.year
          if current_month < reset_month
            if year_format == 'YY-YY'
              year_val = "#{(current_year - 1).to_s[2..-1]}-#{current_year.to_s[2..-1]}"
            else
              year_val = "#{current_year - 1}-#{current_year}" 
            end
          else
            if year_format == 'YY-YY'
              year_val = "#{current_year.to_s[2..-1]}-#{(current_year + 1).to_s[2..-1]}"
            else
              year_val = "#{current_year}-#{current_year + 1}" 
            end
          end
          sequence_format += year_val
        else
          sequence_format += Date.current.strftime('%Y')
        end
      else
        d_format_split = d_format.split('-')
        field_name = d_format_split.first
        if field_name == 'organisation_counter'
          organisation_counter = if sequence_manager.try(:organisation_counter).present?
                                    sequence_manager.organisation_counter.to_s
                                 else
                                    sequence_manager.original_counter.to_s
                                 end
          sequence_format += ("%0#{counter_length}d" % organisation_counter)
        elsif field_name == 'facility_counter'
          facility_counter = if sequence_manager.try(:facility_counter).present?
                                    sequence_manager.facility_counter.to_s
                                 else
                                    sequence_manager.original_counter.to_s
                                 end
          sequence_format += ("%0#{counter_length}d" % facility_counter)
        elsif field_name == 'region_counter'
          region_counter = if sequence_manager.try(:region_counter).present?
                                    sequence_manager.region_counter.to_s
                                 else
                                    sequence_manager.original_counter.to_s
                                 end
          sequence_format += ("%0#{counter_length}d" % region_counter)
        elsif field_name == 'entity_group_counter'
          entity_group_counter = if sequence_manager.try(:entity_group_counter).present?
                                    sequence_manager.entity_group_counter.to_s
                                 else
                                    sequence_manager.original_counter.to_s
                                 end
          sequence_format += ("%0#{counter_length}d" % entity_group_counter)
        elsif field_name == 'store_counter'
          store_counter = if sequence_manager.try(:store_counter).present?
                                    sequence_manager.store_counter.to_s
                                 else
                                    sequence_manager.original_counter.to_s
                                 end
          sequence_format += ("%0#{counter_length}d" % store_counter)
        elsif field_name == 'entity_group_abbreviation'
          sequence_format += entity_group.display_name
        else
          sequence_format += sequence_manager.send(field_name).to_s
        end
      end
      # EOF if d_format.in
    end
    # EOF display_formats each
    sequence_format
  rescue StandardError => e
    sequence_logger.error(" === error in Gen Seq Helper :: #{e.inspect}")
  end
  # EOF sequence_generate
end
