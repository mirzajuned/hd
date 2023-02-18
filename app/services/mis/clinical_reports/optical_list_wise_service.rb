module Mis::ClinicalReports
  class OpticalListWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DATE', 'TOTAL', 'PRESCRIBED', 'CONVERTED'] unless @request == 'json'

        aggregation_query, aggregation_query_count = appointment_list_query

        @optical_lists = PatientOpticalPrescription.collection.aggregate(aggregation_query).to_a || []
        optical_list_count = PatientOpticalPrescription.collection.aggregate(aggregation_query_count).to_a
        total_records = (optical_list_count[0][:optical_list_count] if optical_list_count.count > 0) || 0

        optical_list_data

        [@data_array, total_records]
      end

      private

      def optical_list_data
        @optical_lists.try(:each) do |op_list|
          converted_count = 0
          advised_count = 0
          date = op_list[:_id].to_date.strftime('%d/%m/%Y')
          op_list[:optical_list].each do |list|
            if (list[:advise_glasses] == 'advise' && list[:converted].blank?) || list[:converted] == 'false'
              advised_count += 1
            elsif list[:converted] == 'true'
              converted_count += 1
            end
          end
          total = advised_count + converted_count
          total, converted_count, advised_count = make_anchor_url(total, converted_count, advised_count, date)
          @data_array << [date, total, advised_count, converted_count]
        end
      end

      def make_anchor_url(total, converted_count, advised_count, date)
        if @request == 'json'
          href = @mis_params[:url] + forward_params(date) + back_params
          total = "<a href='#{href}&current_state=all' data-remote='true'>#{total}</a>" if total > 0

          if converted_count > 0
            converted_count = "<a href='#{href}&current_state=converted' data-remote='true'>#{converted_count}</a>"
          end

          if advised_count > 0
            advised_count = "<a href='#{href}&current_state=prescribed' data-remote='true'> #{advised_count}</a>"
          end
        end
        [total, converted_count, advised_count]
      end

      def forward_params(date)
        start_date = "&start_date=#{date}"
        end_date = "&end_date=#{date}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=conversion'
        title = '&title=optical_list_state_wise'
        has_params = '&has_params=true'
        store_id = "&store_id=#{@mis_params[:store_id]}"
        store_name = "&store_name=#{@mis_params[:store_name]&.tr("'", '`')}"

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title +
          has_params + store_id + store_name
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
        store_id = "&store_id=#{@mis_params[:store_id]}"
        store_name = "&store_name=#{@mis_params[:store_name]&.tr("'", '`')}"

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length +
          has_params + store_id + store_name
      end

      def appointment_list_query
        # AppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$project": project_options },
          { "$group": group_options },
          { "$sort": { _id: -1 } }
        ]
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # AppointmentList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$project": project_options },
          { "$group": group_options },
          { "$group": { _id: 'null', optical_list_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        # Facility/Organisation

        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { reg_hosp_ids: [@mis_params[:organisation_id]] }
                        end

        # Date
        match_options = match_options.merge(prescription_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                 "$lte": @mis_params[:end_date].end_of_day })

        match_new = match_prescribed_data
        match_options = match_options.merge(match_new)
        match_options = match_options.merge(is_deleted: false)
        match_options = match_options.merge(store_id: BSON::ObjectId(@mis_params[:store_id])) if @mis_params[:store_id].present?
        match_options
      end

      def group_options
        { _id: '$date', optical_list: { "$push": { converted: '$converted', advise_glasses: '$advise_glasses',
                                                   store_id: '$store_id' } } }
      end

      def project_options
        {
          converted: 1,
          advise_glasses: 1,
          encounterdate: 1,
          store_id: 1,
          date: { "$dateToString": { format: '%Y-%m-%d', date: '$encounterdate' } }

        }
      end

      def match_prescribed_data
        # this logic advise_glasses: '' blank was changed , but for older data we will keep this
        {
          "$or": [
            {
              "$and": [
                { "advise_glasses": '' },
                { "converted": 'true' }
              ]
            },
            {
              "advise_glasses": 'advise'
            }
          ]
        }
      end
    end
  end
end
