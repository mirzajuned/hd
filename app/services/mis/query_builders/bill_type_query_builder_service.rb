module Mis::QueryBuilders
  class BillTypeQueryBuilderService
    class << self
      def call(mis_params, request)
        @request = request
        @mis_params = mis_params
        @display_length = @mis_params[:iDisplayLength].to_i
        @display_start = @mis_params[:iDisplayStart].to_i
        @report_name = @mis_params[:title]
        mis_query_logger = Logger.new("#{Rails.root}/log/mis_query_logger.log")
        default_report_array
        mis_query_logger.info(" ============ MIS params: #{@mis_params.inspect}")
        # begin
          if @stats_reports.include?(@report_name)
            aggregation_query = [
              { "$match": match_options },
              { "$group": group_options },
              { "$sort": { '_id': -1 } }
            ]
            mis_query_logger.info(" ============ match_options: #{match_options}")
          else
            aggregation_query = [
              { "$match": match_options },
              { "$sort": { 'receipt_time': -1 } }
            ]
            if @request != 'json'
              aggregation_query << { "$limit": 3000 }
              aggregation_query << { "$group": group_options } 
            end
          end
          if @request == 'json'
            aggregation_query << { "$facet": facet_options }
          end
          aggregation_query
        # rescue Exception => e
        #   mis_query_logger.info(" ============ Exception: #{e.inspect}")
        #   mis_query_logger.info(" ============ Match options: #{match_options.inspect}")
        # end
      end

      def match_options
        match_options = {}
        if @detailed_reports.include?(@report_name)
          match_options = revenue_report_match
        elsif @stats_reports.include?(@report_name)
          match_options = revenue_statistics_match
        end
        match_options
      end
      # EOF match_options

      def group_options
        group_options = {}
        if @detailed_reports.include?(@report_name)
          group_options = { _id: 'null', data: { "$push": '$$ROOT' }, total: { "$sum": 1 } }
        elsif @stats_reports.include?(@report_name)
          group_options = { _id: '$service_type_code_name', data: { "$push": '$$ROOT' }, total: { "$sum": 1 } }
        end
        group_options
      end
      # EOF group_options

      def facet_options
        { metadata: [ { "$count": "total" } ], data: [ { "$skip":  @display_start }, { "$limit":  @display_length } ] }
      end
      # EOF project_options

      def revenue_report_match
        match_options = default_condition(@report_name)
        # Facility/Organisation
        if @mis_params[:facility_id].present?
          match_options[:facility_id] = @mis_params[:facility_id]
        else
          match_options[:organisation_id] = @mis_params[:organisation_id]
        end

        # Date/Time
        match_options[:receipt_date] = { "$gte": @mis_params[:start_date].beginning_of_day,
                                                            "$lte": @mis_params[:end_date].end_of_day }
        # Department
        if @mis_params[:department_id].present?
          match_options[:department_id] = @mis_params[:department_id]
        end
        match_options
      end
      # EOF revenue_report_match

      def revenue_statistics_match
        match_options = default_condition(@report_name)
        # Facility/Organisation
        if @mis_params[:facility_id].present?
          match_options['facility_id'] = BSON::ObjectId(@mis_params[:facility_id])
        else
          match_options['organisation_id'] = BSON::ObjectId(@mis_params[:organisation_id])
        end
        # Date/Time
        match_options['receipt_date'] = { "$gte": @mis_params[:start_date].beginning_of_day,
                                          "$lte": @mis_params[:end_date].end_of_day }
        # Department
        # match_options['department_id'] = @mis_params[:department_id] if @mis_params[:department_id].present?
        match_options
      end
      # EOF revenue_statistics_match

      def default_report_array
        @detailed_reports = ['']
        @stats_reports = ['optical_bill_type_stats']
      end
      # EOF default_report_array

      def default_condition(report_name)
        match_hash = {}
        if report_name == 'optical_bill_type_stats'
          match_hash.merge!({ department_id: 50121007 })
        end
        match_hash
      end
      # EOF default_condition
    end
  end
end
