module Mis::ClinicalReports
  class ClinicalUtility
    class << self
      def clinical_location_data(location, href_req, loc_type, app_type = 'appointment')
        type_count = location[:count]
        type = location[:_id] || '<i>No city</i>'
        nil_count, zero_plus, twenty_plus, forty_plus, sixty_plus, male_count, female_count, others_count = [0] * 8
        frequency = Hash.new(0)
        age_frequency = { zero_plus: 0, twenty_plus: 0, forty_plus: 0, sixty_plus: 0 }
        location[:appointment_lists].each do |apt_list|
          age = !apt_list[:patient_age].blank? ? apt_list[:patient_age].split('-')[0] : nil
          age_array = [zero_plus, twenty_plus, forty_plus, sixty_plus]
          if age.blank?
            nil_count += 1
          else
            age_frequency = extract_age(apt_list[:age], age_frequency)
          end

          gender = apt_list[:patient_gender] unless apt_list[:patient_gender].blank?
          gender_count = [male_count, female_count, others_count]
          male_count, female_count, others_count = extract_gender(gender, gender_count) unless gender.blank?
          frequency[apt_list[:appointment_type]] += 1
        end
        counter_values = [type_count, nil_count, male_count, female_count, others_count, age_frequency, frequency]
        type_count, nil_count, male_count, female_count, others_count, age_frequency, frequency = make_anchor_url(counter_values, type, href_req, loc_type)
        appointment_type = if app_type == 'appointment'
                             Mis::ClinicalReportsHelper.appointment_type_in_html(frequency).html_safe
                           end
        age = Mis::ClinicalReportsHelper.appointment_type_in_html(age_frequency).html_safe || '--'
        [type, type_count, age, nil_count, male_count, female_count, others_count, appointment_type]
      end

      def extract_age(age, age_frequency)
        case age.to_i
        when 0..19
          age_frequency[:zero_plus] += 1
        when 20..39
          age_frequency[:twenty_plus] += 1
        when 40..59
          age_frequency[:forty_plus] += 1
        else
          age_frequency[:sixty_plus] += 1
        end
        age_frequency
      end

      def extract_gender(gender, gender_count)
        male_count, female_count, others_count = gender_count
        case gender
        when 'Male'
          male_count += 1
        when 'Female'
          female_count += 1
        else
          others_count += 1
        end
        [male_count, female_count, others_count]
      end

      def make_anchor_url(counter_values, type, href_req, loc_type)
        type_count, nil_count, male_count, female_count, others_count, age_frequency, frequency = counter_values
        href, request = href_req

        if request == 'json'
          if male_count > 0
            male_count = "<a href='#{href}&gender_type=Male&loc_type=#{loc_type}&loc=#{type}' data-remote='true'> #{male_count}</a>"
          end
          if female_count > 0
            female_count = "<a href='#{href}&gender_type=Female&loc_type=#{loc_type}&loc=#{type}' data-remote='true'> #{female_count}</a>"
          end
          if others_count > 0
            others_count = "<a href='#{href}&gender_type=Transgender&loc_type=#{loc_type}&loc=#{type}' data-remote='true'> #{others_count}</a>"
          end
          if nil_count > 0
            nil_count = "<a href='#{href}&age_type=nil_count&loc_type=#{loc_type}&loc=#{type}' data-remote='true'> #{nil_count}</a>"
          end
          if type_count > 0
            type_count = "<a href='#{href}&loc_type=#{loc_type}&loc=#{type}' data-remote='true'> #{type_count}</a>"
          end
          frequency = appointment_type_in_url(frequency, href, type, loc_type)
          age_frequency = age_url(age_frequency, href, type, loc_type) || '--'
        end
        [type_count, nil_count, male_count, female_count, others_count, age_frequency, frequency]
      end

      def appointment_type_in_url(frequency, href, type, loc_type)
        frequency.each do |k, v|
          frequency[k] = "<a href='#{href}&appointment_status=#{k}&loc_type=#{loc_type}&loc=#{type}' data-remote='true'> #{v}</a>"
        end
      end

      def age_url(age_frequency, href, type, loc_type)
        age_frequency.each do |key, value|
          if value > 0
            age_frequency[key] = "<a href='#{href}&age_type=#{key}&loc_type=#{loc_type}&loc=#{type}' data-remote='true'>#{value}</a>"
          end
          age_frequency
        end
      end
    end
  end
end
