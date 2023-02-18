class Api::V2::MedicineService
  class << self
    include ActionView::Helpers::TextHelper

    def medication_table_json(opd_record, current_facility, doc_name, date)
      @opdrecord = opd_record
      medication_table_array = []
      medication_groups = @opdrecord.treatmentmedication.group_by(&:status)
      medication_set_arr = Global.send('medication_instruction_option').send('sets')

      [nil, 'C', 'D'].each do |mg|
        if medication_groups.to_h[mg].present?
          med_table_data = []

          medication_groups.to_h[mg].each do |medication|
            medicine_hash = OpdRecordsHelper.phr_medication_table(medication, @translated_language, current_facility)
            medicine_hash['date'] = date
            medicine_hash['doctor'] = doc_name
            med_table_data << medicine_hash
          end
        end
        medication_table_array << med_table_data
      end

      medication_table_array.flatten.reject(&:blank?)
    end
  end
end
