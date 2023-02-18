module Mis::ClinicalReports
  class AppointmentPatientListWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << %w(DATE 0-19(AGE) 20-39(AGE) 40-59(AGE) 60+(AGE) UNDEFINED MALE FEMALE OTHER(GENDER) TYPE)
        end

        @appointment_lists = AppointmentListView.collection.aggregate(appointment_list_query[0]).to_a || []
        admission_list_count = AppointmentListView.collection.aggregate(appointment_list_query[1]).to_a
        total_records = (admission_list_count[0][:appointmet_list_count] if admission_list_count.count > 0) || 0
        appointment_list_data
        [@data_array, total_records]
      end

      private

      def appointment_list_data
        @appointment_lists.try(:each) do |list|
          appointment_date = list[:_id].strftime("%d/%m/%Y")
          nil_count, zero_plus, twenty_plus, forty_plus, sixty_plus, male_count, female_count, others_count = [0] * 8
          frequency = Hash.new(0)

          list[:appointment_lists].each do |apt_list|
            age = !apt_list[:patient_age].blank? ? apt_list[:patient_age].split("-")[0] : nil
            age_array = [zero_plus, twenty_plus, forty_plus, sixty_plus]
            if age.blank?
              nil_count += 1
            else
              zero_plus, twenty_plus, forty_plus, sixty_plus = extract_age(apt_list[:age], age_array)
            end

            gender = apt_list[:patient_gender] if !apt_list[:patient_gender].blank?
            gender_count = [male_count, female_count, others_count]
            male_count, female_count, others_count = extract_gender(gender, gender_count) if !gender.blank?
            frequency[apt_list[:appointment_type]] += 1
          end
          counter_values = [nil_count, zero_plus, twenty_plus, forty_plus, sixty_plus, male_count, female_count, others_count, frequency]
          nil_count, zero_plus, twenty_plus, forty_plus, sixty_plus, male_count, female_count, others_count, frequency = make_anchor_url(counter_values, appointment_date)
          appointment_type = Mis::ClinicalReportsHelper.appointment_type_in_html(frequency).html_safe
          @data_array << [appointment_date, zero_plus, twenty_plus, forty_plus, sixty_plus, nil_count, male_count, female_count, others_count, appointment_type]
        end
      end

      def extract_age(age, age_array)
        zero_plus, twenty_plus, forty_plus, sixty_plus = age_array
        case age.to_i
        when 0..19
          zero_plus += 1
        when 20..39
          twenty_plus += 1
        when 40..59
          forty_plus += 1
        else
          sixty_plus += 1
        end
        return zero_plus, twenty_plus, forty_plus, sixty_plus
      end

      def extract_gender(gender, gender_count)
        male_count, female_count, others_count = gender_count
        case gender
        when "Male"
          male_count += 1
        when "Female"
          female_count += 1
        else
          others_count += 1
        end
        return male_count, female_count, others_count
      end

      def forward_params(appointment_date)
        start_date = "&start_date=#{appointment_date}"
        end_date = "&end_date=#{appointment_date}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=outpatient'
        title = '&title=appointment_list_wise'
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title + has_params
      end

      def back_params
        back_start_date = "&back_start_date=#{@mis_params[:start_date]}"
        back_end_date = "&back_end_date=#{@mis_params[:end_date]}"
        back_time_period = "&back_time_period=#{@mis_params[:time_period]}"
        back_group = "&back_group=#{@mis_params[:group]}"
        back_title = "&back_title=#{@mis_params[:title]}"
        back_skip = "&back_iDisplayStart=#{@mis_params[:iDisplayStart]}"
        back_length = "&back_iDisplayLength=#{@mis_params[:iDisplayLength]}"
        has_params = '&has_params=true'

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length + has_params
      end

      def make_anchor_url(counter_values, appointment_date)
        nil_count, zero_plus, twenty_plus, forty_plus, sixty_plus, male_count, female_count, others_count, frequency = counter_values
        if @request == 'json'
          href = @mis_params[:url] + forward_params(appointment_date) + back_params
          if zero_plus > 0
            zero_plus = "<a href='#{href}&age_type=zero_plus' data-remote='true'>#{zero_plus}</a>"
          end

          if twenty_plus > 0
            twenty_plus = "<a href='#{href}&age_type=twenty_plus' data-remote='true'>#{twenty_plus}</a>"
          end

          if forty_plus > 0
            forty_plus = "<a href='#{href}&age_type=forty_plus' data-remote='true'>#{forty_plus}</a>"
          end

          if sixty_plus > 0
            sixty_plus = "<a href='#{href}&age_type=sixty_plus' data-remote='true'>#{sixty_plus}</a>"
          end

          if male_count > 0
            male_count = "<a href='#{href}&gender_type=Male' data-remote='true'> #{male_count}</a>"
          end
          if female_count > 0
            female_count = "<a href='#{href}&gender_type=Female' data-remote='true'> #{female_count}</a>"
          end
          if others_count > 0
            others_count = "<a href='#{href}&gender_type=Transgender' data-remote='true'> #{others_count}</a>"
          end
          if nil_count > 0
            nil_count = "<a href='#{href}&age_type=nil_count' data-remote='true'> #{nil_count}</a>"
          end
          frequency = appointment_type_in_url(frequency, href)
        end
        return nil_count, zero_plus, twenty_plus, forty_plus, sixty_plus, male_count, female_count, others_count, frequency
      end

      def appointment_type_in_url(frequency, href)
        frequency.each { |k, v|
          frequency[k] = "<a href='#{href}&appointment_status=#{k}' data-remote='true'> #{v}</a>"
        }
      end

      def appointment_list_query
        # AppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options },
          # {"$unwind": "$appointment_lists" },
          # {"$group": group_by_gender },
          { "$sort": { '_id': -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # OtList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": group_options },
          { "$group": { _id: 'null', appointmet_list_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }
                        end

        # Date
        match_options = match_options.merge(current_state: { "$nin": ["Deleted"] })
        match_options = match_options.merge(appointment_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })
      end

      def group_options
        { _id: '$appointment_date',
          appointment_lists: { "$push": { appointment_id: '$appointment_id', appointment_date: '$appointment_date',
                                          patient_age: '$patient_age', age: '$age', patient_gender: '$patient_gender',
                                          appointment_type: '$appointment_type' } },
          appointment_count: { "$sum": 1 } }
      end
    end
  end
end
