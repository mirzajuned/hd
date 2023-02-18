module Inventory::Department::OpticalHelper
  def self.get_prescription_values(prescription, flag)
    type = get_prescription_type(prescription.prescription_type, flag)
    main_keys = flag == 'prescription' ? get_prescription_keys : get_acceptance_keys

    optical_hash = {}

    ['r', 'l'].each do |side|
      main_keys.each_with_index do |key|
        final_key = side + '_' + type + '_' + key

        value = prescription.read_attribute("#{final_key}")
        optical_hash[side + '_' + key] = value.present? ? value : '--'
      end
    end

    show_add_key = type + '_show_add'
    # optical_hash[:show_add] = prescription.read_attribute("#{show_add_key}")
    optical_hash[:show_add] = true # Now in optical store add should be always there

    return optical_hash
  end

  def self.get_prescription_keys
    main_values = ["distant_axis", "distant_cyl", "distant_sph", "distant_vision", "near_axis", "near_cyl", "near_sph", "near_vision", "add_axis", "add_cyl", "add_sph", "add_vision", "dia", "size", "fittingheight", "prismbase"]

    return main_values
  end

  def self.get_acceptance_keys
    main_values = [ "framematerial","ipd", "distance_pd", "near_pd", "lensmaterial", "lenstint", "typeoflens", "comments", "dia", "size", "fittingheight", "prismbase"]
    # titles = ["Frame Material- ", "IPD - ", "Lens Material- ", "Lens Tint- ", "Type of Lens - "]

    return main_values
  end

  def self.get_prescription_type(type, type_for)
    if type_for == 'prescription'
      if type.present? && type.include?('intermediate')
        glass_type = 'intermediate_glasses_prescriptions'
      else
        glass_type = 'glassesprescriptions'
      end

    else
      if type.present? && type.include?('intermediate')
        glass_type = 'intermediate_acceptance'
      else
        glass_type = 'acceptance'
      end
    end
  end
end
