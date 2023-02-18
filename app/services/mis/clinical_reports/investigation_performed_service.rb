module Mis::ClinicalReports
  class InvestigationPerformedService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []
        @mis_params[:initial_age] = nil
        @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params) unless @request == 'json'
        @stats_lists = MisClinical::Opd::InvestigationConversion.collection.aggregate(query).to_a || []
        if @request == 'json'
          total_records = (MisClinical::Opd::InvestigationConversion.collection.aggregate(count_query).to_a || []).size
        else
          total_records = 0
        end

        procedure_list_data
        [@data_array, total_records]
      end

      private

      def procedure_list_data
        @stats_lists = @stats_lists.group_by { |record| record[:_id][:investigation_date].strftime('%d/%m/%Y') }
        @stats_lists.each do |date, investigation_list|
          inv_date = date
          investigation_list.each_with_index do |data, index|
            total_performed = data[:total_performed]
            investigation_type = data[:_id][:investigation_type]
            total_conversion_days = data[:conversion_time_days_total]
            avg_conversion = total_performed > 0 ? (total_conversion_days.to_f / total_performed).round(2) : 0
            avg_conversion = avg_conversion > 0 ? avg_conversion : '0'
            if @request == 'json'
              href = @mis_params[:url] + forward_params(inv_date) + back_params
              inv_type = "Investigation::#{investigation_type}"
              date = '' if index > 0
              total_performed = "<a href='#{href}&investigation_date_wise=performed&investigation_state=performed&investigation_type=#{inv_type}' data-remote='true'>#{total_performed.to_i}</a>"
            end
            @data_array << [date, investigation_type, total_performed, avg_conversion]
          end
        end
        @data_array
      end

      def forward_params(date)
        start_date = "&start_date=#{date}"
        end_date = "&end_date=#{date}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=investigation'
        title = '&title=investigation_detail'
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title +
          has_params
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

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length +
          has_params
      end

      def query
        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options },
          { "$sort": { '_id.investigation_date': -1, '_id.investigation_type': 1 } }
        ]

        if @request == 'json'
          aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i }
          aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i }
        end
        aggregation_query
      end

      def count_query
        aggregation_query = [
          { "$match": match_options }
        ]
        aggregation_query + [{ "$group": group_options }]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          facilities_ids = Organisation.find_by(id: BSON::ObjectId(@mis_params[:organisation_id]))
                                                       .facilities
                                                       .pluck(:id)
                          { facility_id: { "$in": facilities_ids } }
                        end
        match_options = match_options.merge('investigation_date': { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                    "$lte": @mis_params[:end_date].end_of_day })
        match_options.merge('total_performed': { '$gt': 0 })
      end

      def group_options
        { _id: { investigation_date: '$investigation_date', investigation_type: '$investigation_type' },
          total_performed: { '$sum': '$total_performed' },
          conversion_time_days_total: { '$sum': '$conversion_time_days_total' } }
      end
    end
  end
end
