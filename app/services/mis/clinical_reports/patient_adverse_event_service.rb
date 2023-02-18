module Mis::ClinicalReports
  class PatientAdverseEventService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []
        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params)
        end
        aggregation_query, aggregation_query_count = adverse_event_list_query
        @adverse_events = AdverseEvent.collection.aggregate(aggregation_query).to_a || []
        @adverse_event_count = AdverseEvent.collection.aggregate(aggregation_query_count).to_a
        unless @request == 'json'
          if @adverse_event_count == 'nil'
            total_records = 0
          else
            total_records = @adverse_event_count.count
          end
        else
          total_records = @adverse_event_count.count
        end
        adverse_event_list_data
        [@data_array, total_records]
      end

      private

      def adverse_event_list_data
        @adverse_events.each do |event|
          description = []
          comment_key = ''
          second_stage_key = ''
          occured_date = event[:occured_date]&.localtime&.strftime("%d %b %Y")
          occured_time = event[:occured_time]&.localtime&.strftime("%I:%M %p")
          event_time = occured_date + '  '  + occured_time
          patient_mrn = event[:patient_mrn].present? ? event[:patient_mrn] : '--'
          name = event[:patient_name] || '--'
          phone = event[:patient_mobilenumber] || '--'
          age = event[:patient_exact_age] || '--'
          age_in_no = event[:patient_age] || '--'
          gender = event[:patient_gender] || '--'
          patient_details = name.titleize + '  ' + phone + '  ' + age + '  ' + gender
          event_type = event[:type].titleize
          sub_speciality = event[:sub_speciality].try(:titleize)
          reported_by = User.find_by(id: event[:user_id]).try(:fullname).titleize
          method_management = event[:method_management].present? ? event[:method_management].titleize : '-'
          final_outcome = event[:final_outcome].present? ? event[:final_outcome].titleize : '-'
          outcome_report = "<a href='/adverse_events/outcome_report' data-remote='true' data-toggle='modal' data-target='#adverse-event-modal'><span class='badge badge-info'>View</span></a>"

          event.keys.each do |key|
            if event[key].present? && event[key] == true
              if event[:type] == 'major'
                description << YAML.load_file("#{Rails.root}/config/mis/adverse_event_description.yml")[key]
              end
              if ['critical', 'minor'].include?(event[:type])
                fields = YAML.load(File.read("#{Rails.root}/config/global/adverse_events.yml"))['default']["#{event[:type]}_options"].values.flatten
                description << (Hash[fields.map{|e| [e['value'], e['name']]}] || {}).with_indifferent_access[key]
              end

              second_stage_key = key + '_one'
              comment_key = key + '_comment'
            end
          end
          comment = event[comment_key] || '--'
          second_stage_value = event[second_stage_key] || '--'
          third_stage_key = 'major_' + second_stage_value if second_stage_value.present?
          third_stage_value = if event.present? && third_stage_key.present?
                                event[third_stage_key].to_s&.split(',')&.join(" , ")
                              else
                                '--'
                              end

          unless @request == 'json'
            @data_array << [occured_date, occured_time, patient_mrn, name, age_in_no, gender, phone, sub_speciality, event_type, description.join(''), second_stage_value.try(:titleize), third_stage_value.try(:titleize), comment.try(:titleize), reported_by, event[:concerned_person_name].try(:titleize), method_management, final_outcome]
          else
            event_time = occured_date + '<br>'  + occured_time
            patient_details = "<b> #{name.titleize} </b>" + '<br>' + phone + '<br>'  + age + '<br>' + Mis::Constants::Badge.gender_type(gender)
            patient_details = "<span class='style=text-align: justify'>" + patient_details  + "</span>"
            event_category = Mis::Constants::Badge.event_category(event_type)
            final_description = if description.present?
                                  if description.join('').length >= 35
                                    description.join('').scan(/.{35}/).join('<br>')
                                  else
                                    description.join('')
                                  end
                                else
                                  '--'
                                end
            if second_stage_value.present? && third_stage_value.present?
              event_description = final_description + '<br>' + second_stage_value.titleize + '<br>' + third_stage_value.titleize
            elsif second_stage_value.present?
              event_description = final_description + '<br>' + second_stage_value.titleize
            else
              event_description = final_description
            end
            final_comment = if comment.present?
                              if comment.length >= 35
                                comment.scan(/.{35}/).join('<br>')
                              else
                                comment
                              end
                            else
                              '--'
                            end

            @data_array << [event_time, patient_mrn, patient_details, sub_speciality, event_category,
                          event_description, final_comment.titleize, reported_by, event[:concerned_person_name].titleize, method_management, final_outcome, outcome_report]
          end
        end
      end

      def adverse_event_list_query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { "occured_date_time": -1 } }
        ]
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        aggregation_query_count = [
          { "$match": match_options }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        #Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }
                        end

        #Date
        match_options = match_options.merge(occured_date: { "$gte": @mis_params[:start_date],
                                                            "$lte": @mis_params[:end_date] })
        #Gender
        match_options = match_options.merge(patient_gender: @mis_params[:gender_type]) if @mis_params[:gender_type].present?

        #Age
        match_options = match_options.merge(patient_age: { "$gte": @mis_params[:initial_age].to_i, "$lte": @mis_params[:final_age].to_i }) if @mis_params[:initial_age].present? && @mis_params[:final_age].present? && @mis_params[:final_age].to_i != 0

        if @mis_params[:final_age].present? && (@mis_params[:final_age] == 'undefined' || @mis_params[:final_age] == 0)
          match_options = match_options.merge(patient_age: nil)
        end

        #Person Responsible
        match_options = match_options.merge(concerned_person: BSON::ObjectId(@mis_params[:person_responsible])) if @mis_params[:person_responsible].present?

        #event category
        match_options = match_options.merge(type: @mis_params[:event_category]) if @mis_params[:event_category].present?

        #event description
        match_options = match_options.merge(@mis_params[:event_description].to_sym => true) if @mis_params[:event_description].present?

        #major sub category
        if @mis_params[:event_description].present? && @mis_params[:sub_category].present?
          sub_category_key = @mis_params[:event_description] + '_one'
          match_options = match_options.merge("#{sub_category_key}": @mis_params[:sub_category]) if sub_category_key.present?
        end

        match_options
      end
    end
  end
end
