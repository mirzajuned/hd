module Mis::ClinicalReports
  class CampWiseConvertedService
    class << self
      def call(mis_params,request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['CAMP', 'COMMUNE', 'TOTAL', 'CONVERTED', 'NOT CONVERTED'] unless @request == 'json'

        @country_id = ""
        @country_id = Facility.find_by(id: @mis_params[:facility_id]).country_id if @mis_params[:facility_id].present?
        unless @request == 'json'
          if @country_id == 'VN_254'
            @data_array[0][1] = "COMMUNE"
          elsif @country_id == 'KH_039'
            @data_array[0][1] = "DISTRICT"
          elsif @country_id.length > 1 
            @data_array[0][1] = "CITY"
          else
            @data_array[0][1] = "CITY / COMMUNE / DISTRICT"
          end
        end
        aggregation_query, aggregation_query_count = patient_list_query
        @patient = CampPatient.collection.aggregate(aggregation_query).to_a || []
        @patient_count = CampPatient.collection.aggregate(aggregation_query_count).to_a
        total_records = (@patient_count[0][:total_records] if @patient_count.count > 0) || 0
        patient_list_data(@country_id)

        # hve to make change here
        [@data_array, total_records]
      end

      private

      def patient_list_data(country_id)
        @patient.each do |patient|
          converted_count = 0
          not_converted_count = 0
          camp_name = patient[:patient_lists][0][:camp_name]
          patient[:patient_lists].each do |list|
            if list[:converted] == true
              converted_count += 1
            else
              not_converted_count += 1
            end
          end
          # show different address as per country
          camp_data = Camp.find_by(username: patient[:_id])
          if camp_data&.country_id == 'VN_254'
            address_identifier = camp_data&.commune
          elsif camp_data&.country_id == 'KH_039'
            address_identifier = camp_data&.district
          else
            address_identifier = camp_data&.city
          end
          total = converted_count + not_converted_count || 0
          total, converted_count, not_converted_count = anchored_count(total, converted_count, not_converted_count, patient[:_id])
          @data_array << [camp_name, address_identifier, total, converted_count, not_converted_count]
        end
      end

      def anchored_count(total, converted_count, not_converted_count, camp_username)
        if @request == 'json'
          href = @mis_params[:url] + forward_params + back_params
          if total > 0
            total = "<a href='#{href}&camp_username=#{camp_username}'
                                data-remote='true'>#{total}</a>"
          end

          if converted_count > 0
            converted_count = "<a href='#{href}&current_state=converted&camp_username=#{camp_username}'
                                data-remote='true'>#{converted_count}</a>"
          end

          if not_converted_count > 0
            not_converted_count = "<a href='#{href}&current_state=performed&camp_username=#{camp_username}'
                                 data-remote='true'> #{not_converted_count}</a>"
          end
        end
        [total, converted_count, not_converted_count]
      end

      def forward_params
        # Forward Params
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=camp'
        title = '&title=camp_wise_patient_details'
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title + has_params
      end

      def back_params
        # Back Params
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

      def patient_list_query
        # PatientType Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options }
        ]
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'
        # PatientType Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": group_options },
          { "$group": { _id: 'null', total_records: { "$sum": 1 } } }
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
        match_options = match_options.merge(created_at: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                          "$lte": @mis_params[:end_date].end_of_day })
      end

      def group_options
        if @country_id == 'VN_254'
        { _id: '$camp_username',
          patient_lists: { "$push": { camp_name: '$camp_name', outreach_patient_id: '$outreach_patient_id',
                                      camp_patient_identifier: '$camp_patient_identifier', commune: '$commune',
                                      converted: '$converted'  } },
          count: { '$sum': 1 } }
        elsif @country_id == 'KH_039'
          { _id: '$camp_username',
            patient_lists: { "$push": { camp_name: '$camp_name', outreach_patient_id: '$outreach_patient_id',
                                      camp_patient_identifier: '$camp_patient_identifier', district: '$district',
                                      converted: '$converted'  } },
            count: { '$sum': 1 } }
        elsif @country_id.length > 1 
          { _id: '$camp_username',
            patient_lists: { "$push": { camp_name: '$camp_name', outreach_patient_id: '$outreach_patient_id',
                                      camp_patient_identifier: '$camp_patient_identifier', city: '$city',
                                      converted: '$converted'  } },
            count: { '$sum': 1 } }
        else
          { _id: '$camp_username',
            patient_lists: { "$push": { camp_name: '$camp_name', outreach_patient_id: '$outreach_patient_id',
                                      camp_patient_identifier: '$camp_patient_identifier', city: '$city', commune: '$commune', district: '$district',
                                      converted: '$converted'  } },
            count: { '$sum': 1 } }
        end
      end
    end
  end
end
