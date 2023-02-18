# rubocop:disable all
module Mis::ClinicalReports
  class UserWiseTatService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []
        @user_list  = MisClinical::Opd::AppointmentTurnAroundTimeData.collection.aggregate(aggregation_query).to_a || []
        aggregation_query_count = MisClinical::Opd::AppointmentTurnAroundTimeData.collection.aggregate(aggregation_count_query).to_a || []
        send("data_collection_#{@request}")
        [@data_array, aggregation_query_count.size]
      end

      def data_collection_xlsx
        @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params)
        @user_list.each do |row|
          if row[:_id][:user_id].present?
            app_date = row[:_id][:appointment_date]&.strftime('%d/%m/%Y')
            @data_array << [app_date, row[:details][:user_name], row[:details][:role_label],
                            row[:totalPatients], to_mins(row[:minTat]), to_mins(row[:maxTat]), (row[:avgTat].to_f/60).round(2), to_mins(row[:totalTat])]
          end
        end
      end

      def data_collection_json
        @collection = @user_list.group_by{|row| row[:_id][:appointment_date]}
        @collection.each do |app_date, details|
          app_date = app_date&.strftime('%d/%m/%Y')
          details.each_with_index do |row, index|
            if row[:_id][:user_id].present?
              min_tat = to_mins row[:minTat]
              max_tat = to_mins row[:maxTat]
              avg_tat = to_mins(row[:avgTat])
              total = format_time(row[:totalTat])
              @data_array << [app_date, row[:details][:user_name], row[:details][:role_label],
                              row[:totalPatients], min_tat, max_tat, avg_tat, total]
              app_date = ''
            end
          end
        end
      end

      def aggregation_query
        query = [
          { '$match': match_options },
          { '$group': group_options },
          { '$sort': { '_id.appointment_date': -1, 'details.user_name': 1  } }
        ]
        query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'
        query
      end

      def aggregation_count_query
        [ { '$match': match_options },
         { '$group': group_options } ]
      end


      def group_options
        {
          _id: {
            user_id: '$user_id',
            appointment_date: '$appointment_date'
          },
          details:  { 
            '$first': {
               user_name: '$user_name',
               role_label: '$role_label'
            } 
          },
          totalPatients: { '$sum': 1 },
          minTat: { '$min': '$aggregated_tat_in_secs'},
          maxTat: { '$max': '$aggregated_tat_in_secs'},
          avgTat: { '$avg': '$aggregated_tat_in_secs'},
          totalTat: {'$sum': '$aggregated_tat_in_secs'}
        }
      end

      def match_options
        match_options = {}
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present? 
                          { 'facility_id': BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { 'organisation_id': (@mis_params[:organisation_id]).to_s }
                        end

        # Date
        if @mis_params[:role_id].present? && @mis_params[:role_id] != 'All' 
          match_options = match_options.merge('role_id': @mis_params[:role_id])
        end
        match_options = match_options.merge(
          'appointment_date': { "$gte": @mis_params[:start_date].beginning_of_day,
                               "$lte": @mis_params[:end_date].end_of_day }
        )

        # match_options = not_arrived_paramas(match_options)
        match_options
      end

      def not_arrived_paramas(match_options)
        match_options.merge!('state': { '$ne': 'not_arrived' })
      end

      def format_time(time_in_ms)
        mins = to_mins(time_in_ms).to_i 
        hh = (mins / 60)
        mm = mins % 60
        "#{hh.to_i} Hrs #{mm.to_i} Mins"
      end

      def to_mins(secs)
        mins = (secs.to_f / 60).round()
        mins > 0 ? mins : '-'
      end

    end
  end
end