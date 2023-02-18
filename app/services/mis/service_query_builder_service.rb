module Mis
  class ServiceQueryBuilderService
    class << self
      def call(mis_params, request)
        @request = request
        @mis_params = mis_params
        @display_length = @mis_params[:iDisplayLength].to_i
        @display_start = @mis_params[:iDisplayStart].to_i
        @report_name = @mis_params[:title]
        mis_query_logger = Logger.new("#{Rails.root}/log/mis_query_logger.log")
        default_report_array
        # begin
          if @detailed_reports.include?(@report_name)
            aggregation_query = [{ "$match": match_options }, { "$sort": { 'service_entry_datetime': -1 } }]
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
          match_options = service_summary_match
        end
        match_options
      end
      # EOF match_options

      def group_options
        group_options = {}
        if @detailed_reports.include?(@report_name)
          group_options = { _id: 'null', data: { "$push": '$$ROOT' }, total: { "$sum": 1 } }
        end
        group_options
      end
      # EOF group_options

      def facet_options
        { metadata: [ { "$count": "total" } ], data: [ { "$skip":  @display_start }, { "$limit":  @display_length } ] }
      end
      # EOF project_options

      def service_summary_match
        match_options = default_condition(@report_name)
        
        # Date/Time
        match_options['service_entry_datetime'] = { "$gte": @mis_params[:start_date].beginning_of_day, "$lte": @mis_params[:end_date].end_of_day }
        
        # Facility/Organisation
        if @mis_params[:facility_id].present?
          match_options[:facility_id] = BSON::ObjectId(@mis_params[:facility_id])
        else
          match_options[:organisation_id] = BSON::ObjectId(@mis_params[:organisation_id])
        end
        
        # Department
        if @mis_params[:department_id].present?
          match_options[:department_id] = @mis_params[:department_id].to_i
        end

        # Invoice/Bill Type
        if @mis_params[:bill_type].present? && @mis_params[:bill_type] != 'all'
          match_options['invoice_display_fields.bill_type'] = @mis_params[:bill_type]
        end

        # Discount Type
        if @mis_params[:discount_type].present?
          match_options[:discount_type] = @mis_params[:discount_type]
        end

        # Added by(User)
        if @mis_params[:user_id].present?
          match_options[:added_by_id] = @mis_params[:user_id]
        end
        
        # bill_entry_type_id(Service/Package ID - description in service)
        if @mis_params[:bill_entry_type_id].present?
          bill_entry_type_ids = @mis_params[:bill_entry_type_id].split(',')
          match_options[:bill_entry_type_id] = { "$in": bill_entry_type_ids }
        end
        
        # sub_specialty_id
        if @mis_params[:sub_specialty_id].present?
          match_options[:sub_specialty_id] = @mis_params[:sub_specialty_id]
        end
        
        match_options
      end
      # EOF service_summary_match

      def default_report_array
        @detailed_reports = ['service_summary', 'package_summary']
      end
      # EOF default_report_array

      def default_condition(report_name)
        match_hash = { is_deleted: false}
        if report_name == 'service_summary'
          match_hash.merge!({bill_entry_type: 'service'})
        elsif report_name == 'package_summary'
          match_hash.merge!({ bill_entry_type: 'surgery_package' })
        end
        
        match_hash
      end
      # EOF default_condition
    end
  end
end
