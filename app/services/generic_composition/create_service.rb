module GenericComposition::CreateService
  def self.call(data)
    return unless data.present?

    medication = data.treatmentmedication
    data.generic_names.delete_all
    medication.each do |med|
      names = med.generic_display_name&.split(',') || []
      generic_ids = med.generic_display_ids&.split(',') || []
      generic_ids.each_with_index do |generic_id, index|
        generic_names = data.generic_names.new
        generic_names.full_name = names[index]
        generic_names.name = names[index]
        generic_names.generic_id = generic_id
        generic_names.medicine_from = med.medicine_from
        generic_names.save
      end
    end
  end
end
