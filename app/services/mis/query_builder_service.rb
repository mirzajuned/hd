# rubocop:disable Metrics/MethodLength
# rubocop:disable Style/ClassAndModuleChildren
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
module Mis
  class QueryBuilderService
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
        begin
          if @stats_reports.include?(@report_name) || @conversion_stats_reports.include?(@report_name)
            aggregation_query = [
              { "$match": match_options },
              { "$group": group_options },
              { "$sort": { '_id': -1 } }
            ]
          elsif @conversion_reports.include?(@report_name)
            aggregation_query = [
              { "$match": match_options },
              { "$sort": { 'advised_on_datetime': -1 } }
            ]
            if @request != 'json'
              aggregation_query << { "$limit": 3000 }
              aggregation_query << { "$group": group_options } 
            end
          else
            aggregation_query = [{ "$match": match_options }]
            if @report_name == 'receipt_summary_by_user'
              aggregation_query << { "$sort": { 'receipt_time': -1 } }
            else
              aggregation_query << { "$sort": { 'receipt_display_fields.bill_date': -1 } }
            end
            if @request != 'json'
              aggregation_query << { "$limit": 3000 }
              aggregation_query << { "$group": group_options } 
            end
          end
          if @request == 'json'
            aggregation_query << { "$facet": facet_options }
          end
          aggregation_query
        rescue Exception => e
          mis_query_logger.info(" ============ Exception: #{e.inspect}")
          mis_query_logger.info(" ============ Match options: #{match_options.inspect}")
        end
      end

      def match_options
        match_options = {}
        if @detailed_reports.include?(@report_name)
          match_options = revenue_report_match
        elsif @stats_reports.include?(@report_name)
          match_options = revenue_statistics_match
        elsif @conversion_reports.include?(@report_name) || @conversion_stats_reports.include?(@report_name)
          match_options = conversion_report_match
        end
        match_options
      end
      # EOF match_options

      def group_options
        group_options = {}
        if @detailed_reports.include?(@report_name) || @conversion_reports.include?(@report_name)
          group_options = { _id: 'null', data: { "$push": '$$ROOT' }, total: { "$sum": 1 } }
        elsif @stats_reports.include?(@report_name)
          group_options = if @report_name == 'bills_by_payer'
                            { _id: '$payer_name', data: { "$push": '$$ROOT' }, total: { "$sum": 1 } }
                          else
                            { _id: '$receipt_date', data: { "$push": '$$ROOT' }, total: { "$sum": 1 } }
                          end
        elsif @conversion_stats_reports.include?(@report_name)
          group_options = { _id: '$advised_on', data: { "$push": '$$ROOT' }, total: { "$sum": 1 } }
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
        if @mis_params[:currency_id].present?
          match_options['receipt_display_fields.currency_id'] = @mis_params[:currency_id]
        end
        # Facility/Organisation
        if @mis_params[:facility_id].present?
          match_options[:facility_id] = @mis_params[:facility_id]
        else
          match_options[:organisation_id] = @mis_params[:organisation_id]
        end
        if @mis_params[:user_id].present?
          if @report_name == 'receipt_summary_by_user'
            match_options[:user_id] = @mis_params[:user_id]
          else
            match_options['user_display_fields.id'] = @mis_params[:user_id]
          end
        end

        # Date/Time
        if @report_name == 'receipt_summary_by_user'
          match_options['receipt_date'] = { "$gte": @mis_params[:start_date].beginning_of_day,
                                                              "$lte": @mis_params[:end_date].end_of_day }
        else
          match_options['receipt_display_fields.bill_date'] = { "$gte": @mis_params[:start_date].beginning_of_day, "$lte": @mis_params[:end_date].end_of_day }
        end

        if @mis_params[:bill_type].present? && @mis_params[:bill_type] != 'all'
          match_options['receipt_display_fields.bill_type'] = @mis_params[:bill_type]
        end
        if @mis_params[:bill_status].present? && @mis_params[:bill_status] != 'all'
          if @mis_params[:bill_status] == 'is_refunded'
            match_options["receipt_display_fields.is_refunded"] = true
            match_options["receipt_display_fields.is_cancelled"] = false
          else
            # match_options["receipt_display_fields.is_refunded"] = false
            match_options["receipt_display_fields.is_cancelled"] = true
          end
          # match_options["receipt_display_fields.#{@mis_params[:bill_status]}"] = true
        end
        # Department
        if @mis_params[:department_id].present?
          match_options['receipt_display_fields.department_id'] = @mis_params[:department_id]
        end
        # Payer
        if @mis_params[:payer_name].present?
          match_options['payer_display_fields.payer_name'] = @mis_params[:payer_name]
        end
        # Advance/Bill/Refund
        if @report_name == 'receipt_summary_by_user'
          if @mis_params[:is_advance].present? && @mis_params[:is_advance] == 'false'
            match_options[:is_advance] = false
          end
          if @mis_params[:is_bill].present? && @mis_params[:is_bill] == 'false'
            match_options[:is_bill] = false
          end
          if @mis_params[:is_refund].present? && @mis_params[:is_refund] == 'false'
            match_options[:is_refund] = false
          end
        end
        match_options
      end
      # EOF revenue_report_match

      def revenue_statistics_match
        match_options = default_condition(@report_name)
        # Facility/Organisation
        if @mis_params[:facility_id].present?
          match_options['facility_id'] = @mis_params[:facility_id]
        else
          match_options['organisation_id'] = @mis_params[:organisation_id]
        end
        # Date/Time
        match_options['receipt_date'] = { "$gte": @mis_params[:start_date].beginning_of_day,
                                          "$lte": @mis_params[:end_date].end_of_day }
        # Department
        match_options['department_id'] = @mis_params[:department_id] if @mis_params[:department_id].present?
        # Doctor
        match_options['user_id'] = @mis_params[:user_id] if @mis_params[:user_id].present?
        match_options
      end
      # EOF revenue_statistics_match

      def conversion_report_match
        match_options = {}
        # Date/Time
        # match_options['filter_fields.advised_on_date'] = { "$gte": @mis_params[:start_date].beginning_of_day, "$lte": @mis_params[:end_date].end_of_day }
        
        # Facility/Organisation
        if @mis_params[:facility_id].present?
          match_options['filter_fields.facility_id'] = { "$in": [@mis_params[:facility_id], BSON::ObjectId(@mis_params[:facility_id])] }
        else
          match_options['filter_fields.organisation_id'] = BSON::ObjectId(@mis_params[:organisation_id])
        end
        if @report_name == 'pharmacy_conversion_summary' || @report_name == 'pharmacy_conversion_stats'
          match_options['filter_fields.department_id'] = '284748001'
        elsif @report_name == 'optical_conversion_summary' || @report_name == 'optical_conversion_stats'
          match_options['filter_fields.department_id'] = '50121007'
        end
        if @report_name == 'pharmacy_conversion_summary' || @report_name == 'optical_conversion_summary'
          match_options['advised_on_datetime'] = { "$gte": @mis_params[:start_date].beginning_of_day, "$lte": @mis_params[:end_date].end_of_day }
          match_options['is_deleted'] = false
        else
          match_options['filter_fields.advised_on_date'] = { "$gte": @mis_params[:start_date].beginning_of_day, "$lte": @mis_params[:end_date].end_of_day }
        end
        # Store
        match_options['filter_fields.store_id'] = BSON::ObjectId(@mis_params[:pharmacy_store_id]) if @mis_params[:pharmacy_store_id].present?
        match_options['filter_fields.store_id'] = BSON::ObjectId(@mis_params[:optical_store_id]) if @mis_params[:optical_store_id].present?

        # Converted
        if @mis_params[:conversion_status].present?
          if @mis_params[:conversion_status] == 'converted'
            match_options['filter_fields.is_converted'] = true
          elsif @mis_params[:conversion_status] == 'not_converted'
            match_options['filter_fields.is_converted'] = false
          elsif @mis_params[:conversion_status] == 'advised'
            match_options['filter_fields.is_converted'] = nil
          end
        end
        match_options
      end
      # EOF conversion_report_match

      def default_report_array
        @detailed_reports = ['billing_summary', 'bills_discounted', 'bills_modified', 'advance_receipts', 'receipt_summary_by_user']
        @stats_reports = ['billing_statistics', 'collection_summary', 'bills_by_payer', 'bills_by_package', 'bills_by_services', 'collection_by_user']
        @conversion_reports = ['pharmacy_conversion_summary', 'optical_conversion_summary']
        @conversion_stats_reports = ['pharmacy_conversion_stats', 'optical_conversion_stats']
      end
      # EOF default_report_array

      def default_condition(report_name)
        match_hash = {}
        if report_name == 'billing_statistics'
          match_hash.merge!({ 'has_revenue_data': true })
        elsif report_name == 'collection_summary'
          match_hash.merge!({ 'has_collection_data': true })
        elsif report_name == 'bills_by_services'
          match_hash.merge!({'department_id': { "$ne": nil }})
        elsif @detailed_reports.include?(report_name) && report_name != 'receipt_summary_by_user'
          match_hash.merge!({'receipt_display_fields.state': { "$in": [nil, 'delivered', 'None', 'Settled', 'Received', 'Deleted'] }})
          if report_name == 'advance_receipts'
            match_hash.merge!({'is_advance': true, 'has_refund': false})
          elsif report_name == 'bills_discounted'
            # match_hash.merge!({'receipt_display_fields.total_of_all_discount': { "$gt": 0 }, 'is_advance': false, 'has_refund': false})
            total_discount = {
              "receipt_display_fields.total_discount": {
                '$gt' => 0
              }, "receipt_display_fields.total_of_all_discount": { "$in": [nil, 0] }
            }
            total_of_all_discount = {
              "receipt_display_fields.total_of_all_discount": {
                '$gt' => 0
              }
            }
            match_hash[:"$or"] = [total_discount, total_of_all_discount]
            match_hash.merge!({'is_advance': false, 'has_refund': false})
          elsif report_name == 'bills_modified'
            match_hash.merge!({'has_logs' => true, 'has_refund': false})
          else
            match_hash.merge!({'is_advance': false, 'has_refund': false})
          end
        end
        match_hash.merge!({'is_deleted': false}) if @detailed_reports.include?(report_name)
        match_hash
      end
      # EOF default_condition
    end
  end
end
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Style/ClassAndModuleChildren
# rubocop:enable Metrics/MethodLength
