# rubocop:disable all
module Mis::ClinicalReports
  class CumulativeDoctorProcedureService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []

        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.procedure_filters(@mis_params)
        end
        aggregation_query = admission_list_query
        lists =  MisClinical::Common::UserProcedureConversion.collection.aggregate(aggregation_query).to_a || []
        total_records = unless @request == 'json'
                          @stats_lists = lists || []
                          0
                        else
                          @stats_lists = lists[0][:data] || []
                          lists[0][:metadata].present? ? lists[0][:metadata][0][:total] : 0
                        end
        procedure_list_data
        [@data_array, total_records]
      end

      private

      def procedure_list_data
        @stats_lists.try(:each) do |procedure_list|
          start_date = @mis_params[:start_date].strftime('%d/%m/%Y')
          end_date = @mis_params[:end_date].strftime('%d/%m/%Y')
          range = "#{start_date} - #{end_date}"
          doctor_id =  procedure_list['_id']
          doc_name = User.find_by(id: doctor_id )&.fullname.titleize
          procedure_data = procedure_list['data'].select{|procedure| procedure['user_id'] == doctor_id}
          advised = procedure_data.map{|mip| mip['total_advised']}.map(&:to_f).sum || 0
          self_performed = procedure_data.map{|mip| mip['total_performed_by_self']}.map(&:to_f).sum || 0
          other_performed = procedure_data.map{|mip| mip['total_performed_by_other']}.map(&:to_f).sum || 0
          total_performed = self_performed + other_performed
          time_performed_by_self = procedure_data.map{|mip| mip['time_performed_by_self']}.map(&:to_f).sum || 0

          avg_conversion = self_conversion_percentage = avg_conversion_percentage = 0
          avg_conversion = (time_performed_by_self / total_performed) rescue 0 if total_performed > 0
          avg_conversion = (avg_conversion > 0) ? avg_conversion.round(2) : 0

          self_conversion_percentage = ((self_performed * 100) / advised) rescue 0 if advised > 0 && self_performed > 0
          self_conversion_percentage = (self_conversion_percentage > 0) ? self_conversion_percentage.round(2) : 0

          avg_conversion_percentage = ((total_performed * 100) / advised) rescue 0 if advised > 0 && total_performed > 0
          avg_conversion_percentage = (avg_conversion_percentage > 0) ? avg_conversion_percentage.round(2) : 0

          if @request == 'json'
            href = @mis_params[:url] + forward_params(start_date, end_date) + back_params
            advised = if advised > 0
                        "<a href='#{href}&procedure_date_wise=advised&procedure_state=pre_advised&advised_by=#{doctor_id}&advised_by_name=#{doc_name}' data-remote='true'>#{advised.to_i}</a>"
                      else
                        0
                      end
            self_performed = if self_performed > 0
                          "<a href='#{href}&procedure_date_wise=advised&procedure_state=pre_advised&advised_by=#{doctor_id}&advised_by_name=#{doc_name}&performed_by=#{doctor_id}&performed_by_name=#{doc_name}' data-remote='true'>#{self_performed.to_i}</a>" 
                        else
                          0
                        end
            total_performed = if total_performed > 0
                          "<a href='#{href}&procedure_date_wise=advised&procedure_state=pre_advised&advised_by=#{doctor_id}&advised_by_name=#{doc_name}&procedure_state=performed' data-remote='true'>#{total_performed.to_i}</a>" 
                        else
                          0
                        end
            @data_array << [range, doc_name, advised, self_performed, other_performed.to_i, total_performed, self_conversion_percentage, avg_conversion_percentage, avg_conversion]
          else
            @data_array << [range, doc_name, advised.to_i, self_performed.to_i, other_performed.to_i, total_performed.to_i, self_conversion_percentage, avg_conversion_percentage, avg_conversion]
          end
        end
        @data_array
      end

      def forward_params(start_date, end_date)
        start_date = "&start_date=#{start_date}"
        end_date = "&end_date=#{end_date}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=procedure'
        title = '&title=procedure_detail'
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

      def admission_list_query
        Mis::ClinicalService::CumulativeDoctorProcedureQueryBuilder.call(@mis_params, @request)
      end
    end
  end
end



