module OpdRecordHelpers
  module GlassPrescriptions
    class Intermediate
      def initialize(opd_record)
        @opd_record = opd_record
      end

      def calculate_advice_values
        optical_hash = { glassesprescriptions_counter: 0, r_glasses_prescriptions_counter: 0, l_glasses_prescriptions_counter: 0 }
        main_values = set_field_keys

        ['r', 'l'].each do |side|
          main_values.each do |key|
            final_key = "#{side}_#{key}"
            value = @opd_record.read_attribute("#{final_key}")
            value = value.present? ? value : '--'

            if !final_key.include?('_add_')
              optical_hash[:glassesprescriptions_counter] = optical_hash[:glassesprescriptions_counter].to_i + 1 if value.present? && value != '--'
              optical_hash[:"#{side}_glasses_prescriptions_counter"] = optical_hash[:"#{side}_glasses_prescriptions_counter"].to_i + 1 if value.present? && value != '--'
            end
            optical_hash[final_key] = value
          end
        end

        optical_hash[:show_add] = @opd_record.read_attribute(:intermediate_glasses_prescriptions_show_add)

        return optical_hash
      end

      def calculate_exam_values
        main_values, titles = set_exam_keys
        optical_hash = { r_acceptance_values: '', l_acceptance_values: '' }

        ['r', 'l'].each do |side|
          main_values.each_with_index do |key, i|
            final_key = "#{side}_#{key}"
            value = @opd_record.read_attribute("#{final_key}")

            if value.present?
              final_value = optical_hash[:"#{side}_acceptance_values"].to_s + titles[i].to_s + value.to_s + ', '
              optical_hash[:"#{side}_acceptance_values"] = final_value
            end
          end
        end

        return optical_hash
      end

      private

      def set_field_keys
        main_values = ["intermediate_acceptance_comments", "intermediate_glasses_prescriptions_distant_axis", "intermediate_glasses_prescriptions_distant_cyl", "intermediate_glasses_prescriptions_distant_sph", "intermediate_glasses_prescriptions_distant_vision", "intermediate_glasses_prescriptions_near_axis", "intermediate_glasses_prescriptions_near_cyl", "intermediate_glasses_prescriptions_near_sph", "intermediate_glasses_prescriptions_near_vision", "intermediate_glasses_prescriptions_add_axis", "intermediate_glasses_prescriptions_add_cyl", "intermediate_glasses_prescriptions_add_sph", "intermediate_glasses_prescriptions_add_vision"]

        return main_values
      end

      def set_exam_keys
        main_values = ["intermediate_acceptance_framematerial", "intermediate_acceptance_ipd", "intermediate_acceptance_lensmaterial", "intermediate_acceptance_lenstint", "intermediate_acceptance_typeoflens"]

        titles = ["Frame Material- ", "IPD - ", "Lens Material- ", "Lens Tint- ", "Type of Lens - "]

        return main_values, titles
      end
    end
  end
end
