module Mis::ClinicalReports
  class DoctorAdvisedInvestigationConversionService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []
        @mis_params[:initial_age] = nil
        @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params) unless @request == 'json'
        @advised_investigations = MisClinical::Opd::AdvisedInvestigationConversionUserWise.collection.aggregate(query).to_a || []
        if @request == 'json'
          total_records = (MisClinical::Opd::AdvisedInvestigationConversionUserWise.collection.aggregate(count_query).to_a || []).count
        else
          total_records = 0
        end

        procedure_list_data
        [@data_array, total_records]
      end

      private

      def procedure_list_data
        investigation_list = @advised_investigations.group_by { |inv| inv[:advised_at]&.strftime('%d/%m/%Y') }
        investigation_list.each do |advised_at, investigations|
          investigations.each_with_index do |inv, index|
            advised_at = inv[:advised_at]&.strftime('%d/%m/%Y')
            total_advised = inv[:total_advised]
            total_performed = inv[:total_performed]
            if @request == 'json'
              href = @mis_params[:url] + forward_params(advised_at) + back_params
              total_performed = if total_performed > 0
                                  "<a href='#{href}&investigation_date_wise=advised&investigation_state=performed&advised_by=#{inv[:user_id]}' data-remote='true'>#{total_performed.to_i}</a>"
                                else
                                  '-'
              end
              total_advised = "<a href='#{href}&investigation_date_wise=advised&advised_by=#{inv[:user_id]}' data-remote='true'>#{total_advised.to_i}</a>"
              advised_at = '' if index > 0
            end
            @data_array << [advised_at, inv[:user_name], total_advised, total_performed]
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
          { "$sort": { 'advised_at': -1, 'user_name': 1 } }
        ]
        if @request == 'json'
          aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i }
          aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i }
        end
        aggregation_query
      end

      def count_query
        [
          { "$match": match_options }
        ]
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
        match_options[:user_id] = BSON::ObjectId(@mis_params[:consulting_doctor]) if @mis_params[:consulting_doctor].present?                
        match_options.merge('advised_at': { "$gte": @mis_params[:start_date].beginning_of_day,
                                                            "$lte": @mis_params[:end_date].end_of_day })
      end
    end
  end
end
